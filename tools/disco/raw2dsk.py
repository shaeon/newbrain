#!/usr/bin/env python3
"""
raw2dsk.py - Convert raw NewBrain disk images (e.g. the .dsk files written by
the Delphi NewBrain emulator) into EDSK images the u765-based core can mount.

The input files are plain sector dumps: no header, no track information, just
track after track in the order C0H0, C0H1, C1H0 ... with the sectors of each
track in ID order. This tool wraps them in EDSK track/sector structures,
restoring the 1,6,2,7,... physical interleave of real NewBrain disks.

The geometry is taken from the 64-byte NewBrain disk specification block in
track 0, sector 1, and falls back to the image size when that block is absent.

Usage:
  python3 raw2dsk.py cpmmaster.dsk                 -> cpmmaster.edsk.dsk
  python3 raw2dsk.py *.dsk -d out/                 -> convert a whole folder
  python3 raw2dsk.py disk.img -o disk.dsk -v       -> also list the CP/M files
  python3 raw2dsk.py disk.img --side-order         -> input is side 0, then side 1

Requires td0conv.py in the same directory (it supplies the EDSK writer).
"""

import argparse
import glob
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from td0conv import build_edsk, TD0Error
except ImportError:
    sys.exit("ERROR: td0conv.py must be in the same directory as this script")

SECSIZE = 512
SPT = 10
TRACK_BYTES = SPT * SECSIZE
INTERLEAVE = [1, 6, 2, 7, 3, 8, 4, 9, 5, 10]

# Fallbacks keyed on image size: (cylinders, heads)
BY_SIZE = {
    204800: (40, 1),
    409600: (40, 2),
    819200: (80, 2),
    102400: (20, 1),
}


def read_spec(d):
    """Parse the 64-byte NewBrain disk specification block, or return None."""
    if len(d) < 64:
        return None
    spt_rec, bsh, blm, exm = struct.unpack_from('<HBBB', d, 7)
    dsm, drm = struct.unpack_from('<HH', d, 12)
    al0, al1 = d[16], d[17]
    cks, off = struct.unpack_from('<HH', d, 18)
    cyls = struct.unpack_from('<H', d, 22)[0]
    sides, ncode, spt = d[24], d[26], d[27]
    if blm != (1 << bsh) - 1 or spt_rec == 0 or not 1 <= cyls <= 100:
        return None
    if spt not in (8, 9, 10, 16, 18) or ncode > 3 or sides not in (0, 1, 2):
        return None
    return dict(spec_id=d[0], bls=128 << bsh, exm=exm, dsm=dsm, drm=drm,
                al0=al0, al1=al1, cks=cks, off=off, recs_per_track=spt_rec,
                cyls=cyls, heads=2 if sides else 1, secsize=128 << ncode, spt=spt)


def cpm_catalogue(d, spec):
    """List the CP/M directory: [(user, name, size)] plus free space."""
    bls, dsm, drm, exm = spec['bls'], spec['dsm'], spec['drm'], spec['exm']
    ptr16 = dsm > 255
    base = spec['off'] * spec['spt'] * spec['secsize']
    files, used = {}, set()
    for i in range(drm + 1):
        e = d[base + i * 32: base + i * 32 + 32]
        if len(e) < 32 or e[0] > 15:
            continue
        nm = bytes(b & 0x7F for b in e[1:12]).decode('latin-1')
        name = nm[:8].rstrip() + '.' + nm[8:].rstrip()
        exfull = (e[14] << 5) | e[12]
        recs = 128 * (exfull % (exm + 1)) + e[15]
        blocks = ([int.from_bytes(e[16 + 2 * j:18 + 2 * j], 'little') for j in range(8)]
                  if ptr16 else list(e[16:32]))
        used.update(b for b in blocks if b)
        key = (e[0], name)
        files[key] = files.get(key, 0) + recs * 128
    dirblocks = -(-(drm + 1) * 32 // bls)
    free = (dsm + 1 - dirblocks - len(used - set(range(dirblocks)))) * bls
    return sorted(files.items()), free


def raw_to_edsk(d, cyls, heads, side_order=False, interleave=True, secsize=SECSIZE,
                spt=SPT, creator="raw2dsk.py"):
    order = INTERLEAVE if (interleave and spt == 10) else list(range(1, spt + 1))
    track_bytes = spt * secsize
    code = {128: 0, 256: 1, 512: 2, 1024: 3}[secsize]
    tracks = []
    for c in range(cyls):
        for h in range(heads):
            idx = (h * cyls + c) if side_order else (c * heads + h)
            base = idx * track_bytes
            secs = []
            for sid in order:
                off = base + (sid - 1) * secsize
                data = d[off:off + secsize].ljust(secsize, b'\xe5')
                secs.append(dict(c=c, h=h, id=sid, code=code, flags=0,
                                 size=secsize, data=data, enc=0))
            tracks.append((c, h, secs))
    return build_edsk(tracks, dict(rate=0, fm=False), fill=0xE5, creator=creator)[0]


def convert(path, args, log=print):
    d = open(path, 'rb').read()
    if d[:8] in (b'EXTENDED', b'MV - CPC'):
        log(f"{path}: already a DSK/EDSK image, skipped")
        return
    spec = read_spec(d)
    if spec:
        cyls, heads = spec['cyls'], spec['heads']
        secsize, spt = spec['secsize'], spec['spt']
        log(f"{path}: spec block type {spec['spec_id']}, {cyls} cyl x {heads} head x "
            f"{spt} x {secsize}, {spec['bls']} byte blocks, {spec['drm'] + 1} dir "
            f"entries, {spec['off']} reserved tracks")
    elif len(d) in BY_SIZE:
        cyls, heads = BY_SIZE[len(d)]
        secsize, spt = SECSIZE, SPT
        log(f"{path}: no spec block, assuming {cyls} cyl x {heads} head from the size")
    else:
        log(f"{path}: no spec block and unknown size {len(d)}, skipped")
        return
    if args.cyls:
        cyls = args.cyls
    if args.heads:
        heads = args.heads

    expected = cyls * heads * spt * secsize
    if len(d) != expected:
        log(f"  WARNING: {len(d)} bytes, geometry implies {expected}"
            f" ({'padding' if len(d) < expected else 'ignoring the excess'})")
        d = d.ljust(expected, b'\xe5')[:expected]

    if spec and args.verbose:
        try:
            cat, free = cpm_catalogue(d, spec)
            for (user, name), size in cat:
                log(f"    {user:>2}: {name:<13} {size:7d}")
            log(f"  {len(cat)} files, {free // 1024} KB free")
        except Exception as e:
            log(f"  (could not read the CP/M directory: {e})")

    out = args.output or os.path.join(
        args.dest or os.path.dirname(path) or '.',
        os.path.splitext(os.path.basename(path))[0] + args.suffix + '.dsk')
    with open(out, 'wb') as f:
        f.write(raw_to_edsk(d, cyls, heads, args.side_order,
                            not args.no_interleave, secsize, spt))
    log(f"  -> {out} [EDSK] ({os.path.getsize(out)} bytes)\n")


def main():
    ap = argparse.ArgumentParser(
        description="Convert raw NewBrain disk images to EDSK for the FPGA core")
    ap.add_argument('images', nargs='+', help="raw image files (wildcards allowed)")
    ap.add_argument('-o', '--output', help="output file (single input only)")
    ap.add_argument('-d', '--dest', help="output directory")
    ap.add_argument('--suffix', default='.edsk',
                    help="suffix added to the output name (default: .edsk)")
    ap.add_argument('-v', '--verbose', action='store_true',
                    help="list the CP/M directory of the image")
    ap.add_argument('--side-order', action='store_true',
                    help="input holds all of side 0, then all of side 1")
    ap.add_argument('--no-interleave', action='store_true',
                    help="write sectors 1-10 in order instead of 1,6,2,7,...")
    ap.add_argument('--cyls', type=int, help="override the cylinder count")
    ap.add_argument('--heads', type=int, help="override the head count")
    a = ap.parse_args()

    paths = []
    for pat in a.images:
        paths += sorted(glob.glob(pat)) if any(c in pat for c in '*?[') else [pat]
    paths = [p for p in paths if os.path.isfile(p)]
    if not paths:
        sys.exit("ERROR: no input files found")
    if a.output and len(paths) > 1:
        sys.exit("ERROR: -o can only be used with a single input file")
    if a.dest:
        os.makedirs(a.dest, exist_ok=True)

    for p in paths:
        try:
            convert(p, a)
        except (TD0Error, OSError) as e:
            print(f"{p}: ERROR: {e}\n")


if __name__ == '__main__':
    main()
