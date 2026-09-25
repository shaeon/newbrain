#!/usr/bin/env python3
"""
dir2dsk.py - Build NewBrain CP/M floppy images (EDSK, .dsk) from directories.

One directory -> one image named after the directory:

    python3 dir2dsk.py MYDISK            -> MYDISK.dsk
    python3 dir2dsk.py "*"               -> one .dsk per directory in the cwd
    python3 dir2dsk.py                   -> same as "*"
    python3 dir2dsk.py TOOLS -F 800K     -> force the 800K format
    python3 dir2dsk.py TOOLS -s boot.dsk -> copy the system tracks from boot.dsk

By default the smallest format that fits the files is used: 200K, then 400K,
then 800K. A directory whose files don't fit in 800K is reported and skipped.

The images match the disks produced by td0conv.py from the original Teledisk
images: 512-byte sectors, 10 sectors/track, IDs 1-10 with a 1,6,2,7,... physical
interleave, 2 reserved system tracks, 2K allocation blocks, and the 64-byte
NewBrain disk-specification block in track 0, sector 1.

Requires td0conv.py in the same directory (it supplies the EDSK writer).
"""

import argparse
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from td0conv import build_edsk, TD0Error
except ImportError:
    sys.exit("ERROR: td0conv.py must be in the same directory as this script")

# --------------------------------------------------------------------------
# NewBrain CP/M formats (all: 512-byte sectors, 10 sectors/track, 2 reserved
# tracks, 2048-byte allocation blocks). Values taken from the disk
# specification block of the original Grundy CP/M disks.
# --------------------------------------------------------------------------
SECSIZE = 512
SPT_PHYS = 10                 # physical sectors per track
RECS_PER_TRACK = SPT_PHYS * SECSIZE // 128     # 40 CP/M records per track
BLS = 2048
RESERVED_TRACKS = 2
INTERLEAVE = [1, 6, 2, 7, 3, 8, 4, 9, 5, 10]   # physical order of sector IDs

FORMATS = {
    # name: (cylinders, heads, DSM, DRM, EXM)
    '200K': dict(cyls=40, heads=1, dsm=94,  drm=63,  exm=1),
    '400K': dict(cyls=40, heads=2, dsm=194, drm=63,  exm=1),
    '800K': dict(cyls=80, heads=2, dsm=394, drm=127, exm=0),
}
FORMAT_ORDER = ['200K', '400K', '800K']

# Bytes 0x20-0x3F of the spec block: FDC gap/format parameters, identical on
# all three original formats.
SPEC_TAIL = bytes.fromhex('002a000006280013000001120000021000024c30'
                          '031100022a3004030000ff00')

TEXT_EXT = {'TXT', 'ASM', 'MAC', 'BAS', 'DOC', 'SUB', 'PRN', 'LST',
            'HEX', 'DAT', 'INC', 'LIB', 'C', 'PAS', 'FOR'}


def spec_block(fmt):
    """The 64-byte NewBrain disk specification block (track 0, sector 1)."""
    dsm, drm, exm = fmt['dsm'], fmt['drm'], fmt['exm']
    dirblocks = (drm + 1) * 32 // BLS
    al0 = ((0xFF00 >> dirblocks) & 0xFF) if dirblocks <= 8 else 0xFF
    al1 = ((0xFF00 >> (dirblocks - 8)) & 0xFF) if dirblocks > 8 else 0
    cks = (drm + 1) // 4
    alv = dsm // 8 + 1
    b = bytearray(64)
    b[0:3] = bytes([1, 0, 0])
    b[3:5] = cks.to_bytes(2, 'little')
    b[5:7] = alv.to_bytes(2, 'little')
    # 15-byte CP/M DPB
    b[7:9] = RECS_PER_TRACK.to_bytes(2, 'little')   # SPT (128-byte records)
    b[9] = 4                                        # BSH (2K blocks)
    b[10] = 15                                      # BLM
    b[11] = exm                                     # EXM
    b[12:14] = dsm.to_bytes(2, 'little')
    b[14:16] = drm.to_bytes(2, 'little')
    b[16], b[17] = al0, al1
    b[18:20] = cks.to_bytes(2, 'little')
    b[20:22] = RESERVED_TRACKS.to_bytes(2, 'little')
    # NewBrain-specific tail
    b[22:24] = fmt['cyls'].to_bytes(2, 'little')
    b[24] = 2 if fmt['heads'] == 2 else 0           # double-sided flag
    b[25] = 3
    b[26] = 2                                       # sector size code (512)
    b[27] = SPT_PHYS
    b[28:32] = bytes(4)
    b[32:64] = SPEC_TAIL
    return bytes(b)


def cpm_name(path, used):
    """Turn a host file name into a unique CP/M 8.3 name."""
    base = os.path.basename(path).upper()
    stem, _, ext = base.rpartition('.') if '.' in base else (base, '', '')
    ok = lambda s: ''.join(c if (c.isalnum() or c in "!#$%&'()-@^_`{}~") else '-'
                           for c in s)
    stem, ext = ok(stem)[:8] or 'FILE', ok(ext)[:3]
    n = 1
    while (stem, ext) in used:
        suffix = str(n)
        stem = (stem[:8 - len(suffix)] + suffix)
        n += 1
    used.add((stem, ext))
    return stem, ext


def collect_files(d, recurse=False):
    files = []
    if recurse:
        for root, _, names in os.walk(d):
            files += [os.path.join(root, n) for n in sorted(names)]
    else:
        files = [os.path.join(d, n) for n in sorted(os.listdir(d))
                 if os.path.isfile(os.path.join(d, n))]
    return files


def pad_file(data, ext, pad):
    """Pad to a 128-byte record boundary."""
    if len(data) % 128 == 0:
        return data
    fillb = 0x1A if (pad == 'auto' and ext in TEXT_EXT) or pad == 'ctrlz' else 0x00
    return data + bytes([fillb]) * (128 - len(data) % 128)


def needed_space(files, pad, ptr16):
    """Blocks and directory entries the files will occupy."""
    nptr = 8 if ptr16 else 16
    blocks = entries = 0
    for p in files:
        size = len(pad_file(open(p, 'rb').read(), p.rsplit('.', 1)[-1].upper(), pad))
        nb = max(1, -(-size // BLS))
        blocks += nb
        entries += max(1, -(-nb // nptr))
    return blocks, entries


def dir_entries_for(recs, blocks, exm, ptr16):
    """Split one file into directory entries. Returns [(ex, s2, rc, blocks)]."""
    nptr = 8 if ptr16 else 16
    recs_per_entry = 128 * (exm + 1)
    out, i = [], 0
    while True:
        chunk = blocks[i * nptr:(i + 1) * nptr]
        r = min(recs - i * recs_per_entry, recs_per_entry)
        k = (r - 1) // 128 if r else 0
        exfull = i * (exm + 1) + k
        out.append((exfull & 0x1F, exfull >> 5, r - 128 * k, chunk))
        i += 1
        if i * recs_per_entry >= recs:
            break
    return out


def build_image(files, fmt, pad='auto', system=None, log=print):
    """Build the raw (logical) image of a CP/M disk holding `files`."""
    cyls, heads = fmt['cyls'], fmt['heads']
    dsm, drm, exm = fmt['dsm'], fmt['drm'], fmt['exm']
    ptr16 = dsm > 255
    ntracks = cyls * heads
    track_bytes = SPT_PHYS * SECSIZE
    img = bytearray([0xE5]) * (ntracks * track_bytes)

    # reserved (system) tracks: copy first, then always write the spec block
    # for THIS format over it, so a system copied from another format still
    # describes the disk correctly.
    if system:
        sysdata = open(system, 'rb').read()[:RESERVED_TRACKS * track_bytes]
        img[0:len(sysdata)] = sysdata
        log(f"  system tracks copied from {os.path.basename(system)}")
    img[0:64] = spec_block(fmt)

    data_start = RESERVED_TRACKS * track_bytes
    dirblocks = (drm + 1) * 32 // BLS
    next_block = dirblocks
    entries = []
    used = set()

    for p in files:
        stem, ext = cpm_name(p, used)
        raw = pad_file(open(p, 'rb').read(), ext, pad)
        recs = len(raw) // 128
        nb = -(-len(raw) // BLS)
        if next_block + nb > dsm + 1:
            raise TD0Error(f"out of space writing {stem}.{ext}")
        blocks = list(range(next_block, next_block + nb))
        next_block += nb
        for i, b in enumerate(blocks):
            off = data_start + b * BLS
            img[off:off + BLS] = (raw[i * BLS:(i + 1) * BLS]
                                  .ljust(BLS, b'\xe5'))
        for ex, s2, rc, blk in dir_entries_for(recs, blocks, exm, ptr16):
            entries.append((stem, ext, ex, s2, rc, blk))
        log(f"  {stem:<8}.{ext:<3} {len(raw):7d} bytes  {nb:3d} blocks")

    if len(entries) > drm + 1:
        raise TD0Error(f"{len(entries)} directory entries, only {drm + 1} available")

    dirbuf = bytearray([0xE5]) * ((drm + 1) * 32)
    for i, (stem, ext, ex, s2, rc, blk) in enumerate(entries):
        e = bytearray(32)
        e[0] = 0                                        # user 0
        e[1:12] = (stem.ljust(8) + ext.ljust(3)).encode('ascii')
        e[12], e[13], e[14], e[15] = ex, 0, s2, rc
        if ptr16:
            for j, b in enumerate(blk):
                e[16 + j * 2:18 + j * 2] = b.to_bytes(2, 'little')
        else:
            for j, b in enumerate(blk):
                e[16 + j] = b
        dirbuf[i * 32:(i + 1) * 32] = e
    img[data_start:data_start + len(dirbuf)] = dirbuf

    free = (dsm + 1 - next_block) * BLS
    return bytes(img), free


def raw_to_edsk(img, fmt, interleave=True):
    """Wrap the logical image in EDSK track/sector structures."""
    cyls, heads = fmt['cyls'], fmt['heads']
    order = INTERLEAVE if interleave else list(range(1, SPT_PHYS + 1))
    tracks = []
    for c in range(cyls):
        for h in range(heads):
            base = (c * heads + h) * SPT_PHYS * SECSIZE
            secs = []
            for sid in order:
                off = base + (sid - 1) * SECSIZE
                secs.append(dict(c=c, h=h, id=sid, code=2, flags=0,
                                 size=SECSIZE, data=img[off:off + SECSIZE],
                                 enc=0))
            tracks.append((c, h, secs))
    info = dict(rate=0, fm=False)
    return build_edsk(tracks, info, fill=0xE5, creator="dir2dsk.py")[0]


def process_dir(d, args, log=print):
    files = collect_files(d, args.recurse)
    if not files:
        log(f"{d}: no files, skipped")
        return
    def fits(f):
        blocks, entries = needed_space(files, args.pad, f['dsm'] > 255)
        dirblocks = (f['drm'] + 1) * 32 // BLS
        return (blocks + dirblocks <= f['dsm'] + 1 and entries <= f['drm'] + 1), blocks

    if args.format:
        name = args.format
        fmt = FORMATS[name]
        ok, blocks = fits(fmt)
        if not ok:
            log(f"{d}: does not fit in {name} ({blocks * BLS // 1024} KB), skipped")
            return
    else:
        name = None
        for cand in FORMAT_ORDER:
            ok, blocks = fits(FORMATS[cand])
            if ok:
                name = cand
                break
        if name is None:
            log(f"{d}: {blocks * BLS // 1024} KB of data / too many files "
                f"for the 800K limit, skipped")
            return
        fmt = FORMATS[name]

    out = args.output or (os.path.basename(os.path.normpath(d)).upper() + '.dsk')
    log(f"{d} -> {out}  [{name}, {fmt['cyls']} cyl x {fmt['heads']} head]")
    img, free = build_image(files, fmt, args.pad, args.system, log)
    with open(out, 'wb') as f:
        f.write(raw_to_edsk(img, fmt, not args.no_interleave))
    if args.raw:
        with open(os.path.splitext(out)[0] + '.img', 'wb') as f:
            f.write(img)
    log(f"  {len(files)} files, {free // 1024} KB free\n")


def main():
    ap = argparse.ArgumentParser(
        description="Build NewBrain CP/M EDSK floppy images from directories")
    ap.add_argument('dirs', nargs='*', default=['*'],
                    help="directories or a wildcard (default: every directory here)")
    ap.add_argument('-F', '--format', choices=FORMAT_ORDER,
                    help="force a format instead of the smallest that fits")
    ap.add_argument('-o', '--output', help="output name (single directory only)")
    ap.add_argument('-s', '--system',
                    help="raw image to copy the 2 system tracks from (bootable disk)")
    ap.add_argument('--pad', choices=['auto', 'ctrlz', 'zero'], default='auto',
                    help="record padding: 0x1A for text files (auto), always, or 0x00")
    ap.add_argument('-r', '--recurse', action='store_true',
                    help="include files in subdirectories (flattened)")
    ap.add_argument('--raw', action='store_true', help="also write a raw .img")
    ap.add_argument('--no-interleave', action='store_true',
                    help="write sectors 1-10 in order instead of 1,6,2,7,...")
    a = ap.parse_args()

    targets = []
    for pattern in a.dirs:
        targets += sorted(p for p in glob.glob(pattern) if os.path.isdir(p)) \
            if any(ch in pattern for ch in '*?[') else [pattern]
    targets = [t for t in targets if os.path.isdir(t)]
    if not targets:
        sys.exit("ERROR: no directories found")
    if a.output and len(targets) > 1:
        sys.exit("ERROR: -o can only be used with a single directory")

    for d in targets:
        try:
            process_dir(d, a)
        except TD0Error as e:
            print(f"{d}: ERROR: {e}\n")


if __name__ == '__main__':
    main()
