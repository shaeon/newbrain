#!/usr/bin/env python3
"""
td0conv.py - Convert Sydex Teledisk (.TD0) floppy images to EDSK (.dsk) or raw (.img).

Supports:
  * Normal ("TD") and Advanced ("td", LZHUF-compressed) images, Teledisk 2.x
  * Optional comment block
  * Sector encodings 0 (raw), 1 (repeated 2-byte pattern), 2 (RLE blocks)
  * CRC checks (header, track, sector) reported as warnings
  * Missing / no-data sectors filled with a configurable byte

Output formats:
  edsk (default) "EXTENDED CPC DSK" image, as used by the MiST/MiSTer u765.sv
                 NEC uPD765 core. Keeps the physical sector order (interleave),
                 real sector IDs, sizes and error flags.
  raw            Plain sector dump. Layout C0H0, C0H1, C1H0 ... sectors sorted
                 by ID (use --side-order for all of side 0, then side 1).

Usage:
  python3 td0conv.py DISK.TD0                      -> DISK.dsk (EDSK)
  python3 td0conv.py DISK.TD0 -f raw               -> DISK.img
  python3 td0conv.py DISK.TD0 --cyls 40 -v -o out.dsk
"""

import argparse
import struct
import sys

# --------------------------------------------------------------------------
# Teledisk CRC-16 (poly 0xA097, init 0)
# --------------------------------------------------------------------------
def td_crc(data, crc=0):
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0xA097) if crc & 0x8000 else (crc << 1)
            crc &= 0xFFFF
    return crc


# --------------------------------------------------------------------------
# LZHUF decompressor (Okumura/Yoshizaki), as used by Teledisk "advanced" mode
# --------------------------------------------------------------------------
N = 4096
F = 60
THRESHOLD = 2
N_CHAR = 256 - THRESHOLD + F      # 314
T = N_CHAR * 2 - 1                # 627
R = T - 1                         # 626
MAX_FREQ = 0x8000

D_CODE = ([0x00] * 32 + [c for c in range(0x01, 0x04) for _ in range(16)]
          + [c for c in range(0x04, 0x0C) for _ in range(8)]
          + [c for c in range(0x0C, 0x18) for _ in range(4)]
          + [c for c in range(0x18, 0x30) for _ in range(2)]
          + list(range(0x30, 0x40)))
D_LEN = [3] * 32 + [4] * 48 + [5] * 64 + [6] * 48 + [7] * 48 + [8] * 16
assert len(D_CODE) == 256 and len(D_LEN) == 256


class LZHUF:
    def __init__(self, data):
        self.data = data
        self.pos = 0
        self.bitbuf = 0
        self.bitcnt = 0
        self.freq = [0] * (T + 1)
        self.prnt = [0] * (T + N_CHAR)
        self.son = [0] * T
        self._start_huff()

    # --- bit input (MSB first; returns 0 past end of data) ---
    def get_bit(self):
        if self.bitcnt == 0:
            self.bitbuf = self.data[self.pos] if self.pos < len(self.data) else 0
            self.pos += 1
            self.bitcnt = 8
        self.bitcnt -= 1
        return (self.bitbuf >> self.bitcnt) & 1

    def get_byte(self):
        v = 0
        for _ in range(8):
            v = (v << 1) | self.get_bit()
        return v

    # --- adaptive Huffman tree ---
    def _start_huff(self):
        freq, son, prnt = self.freq, self.son, self.prnt
        for i in range(N_CHAR):
            freq[i] = 1
            son[i] = i + T
            prnt[i + T] = i
        i, j = 0, N_CHAR
        while j <= R:
            freq[j] = freq[i] + freq[i + 1]
            son[j] = i
            prnt[i] = prnt[i + 1] = j
            i += 2
            j += 1
        freq[T] = 0xFFFF
        prnt[R] = 0

    def _reconst(self):
        freq, son, prnt = self.freq, self.son, self.prnt
        j = 0
        for i in range(T):
            if son[i] >= T:
                freq[j] = (freq[i] + 1) // 2
                son[j] = son[i]
                j += 1
        i, j = 0, N_CHAR
        while j < T:
            f = freq[i] + freq[i + 1]
            freq[j] = f
            k = j - 1
            while f < freq[k]:
                k -= 1
            k += 1
            freq[k + 1:j + 1] = freq[k:j]
            freq[k] = f
            son[k + 1:j + 1] = son[k:j]
            son[k] = i
            i += 2
            j += 1
        for i in range(T):
            k = son[i]
            if k >= T:
                prnt[k] = i
            else:
                prnt[k] = prnt[k + 1] = i

    def _update(self, c):
        freq, son, prnt = self.freq, self.son, self.prnt
        if freq[R] == MAX_FREQ:
            self._reconst()
        c = prnt[c + T]
        while True:
            freq[c] += 1
            k = freq[c]
            l = c + 1
            if k > freq[l]:
                while k > freq[l]:
                    l += 1
                l -= 1
                freq[c] = freq[l]
                freq[l] = k
                i = son[c]
                prnt[i] = l
                if i < T:
                    prnt[i + 1] = l
                j = son[l]
                son[l] = i
                prnt[j] = c
                if j < T:
                    prnt[j + 1] = c
                son[c] = j
                c = l
            c = prnt[c]
            if c == 0:
                break

    def _decode_char(self):
        son = self.son
        c = son[R]
        while c < T:
            c = son[c + self.get_bit()]
        c -= T
        self._update(c)
        return c

    def _decode_position(self):
        i = self.get_byte()
        c = D_CODE[i] << 6
        j = D_LEN[i] - 2
        for _ in range(j):
            i = (i << 1) | self.get_bit()
        return c | (i & 0x3F)

    def decompress(self):
        text = bytearray(b' ' * N)
        r = N - F
        out = bytearray()
        # Decode until the compressed input is exhausted. A few trailing
        # garbage bytes may appear; the TD0 parser stops at the 0xFF marker.
        while self.pos < len(self.data):
            c = self._decode_char()
            if c < 256:
                out.append(c)
                text[r] = c
                r = (r + 1) & (N - 1)
            else:
                i = (r - self._decode_position() - 1) & (N - 1)
                for k in range(c - 255 + THRESHOLD):
                    b = text[(i + k) & (N - 1)]
                    out.append(b)
                    text[r] = b
                    r = (r + 1) & (N - 1)
        return bytes(out)


# --------------------------------------------------------------------------
# TD0 parser
# --------------------------------------------------------------------------
DATA_RATES = {0: "250 kbps", 1: "300 kbps", 2: "500 kbps"}
DRIVE_TYPES = {1: '5.25" 360K', 2: '5.25" 1.2M', 3: '3.5" 720K', 4: '3.5" 1.44M',
               5: '8"', 6: '3.5"'}


class TD0Error(Exception):
    pass


def expand_sector(enc, payload, size):
    if enc == 0:
        data = bytes(payload[:size])
    elif enc == 1:
        count, = struct.unpack_from('<H', payload, 0)
        data = bytes(payload[2:4]) * count
    elif enc == 2:
        out = bytearray()
        p = 0
        while len(out) < size and p < len(payload):
            t = payload[p]; p += 1
            if t == 0:
                ln = payload[p]; p += 1
                out += payload[p:p + ln]; p += ln
            else:
                blk = 1 << t
                rep = payload[p]; p += 1
                out += payload[p:p + blk] * rep; p += blk
        data = bytes(out)
    else:
        raise TD0Error(f"unknown sector encoding {enc}")
    if len(data) != size:
        data = (data + bytes(size))[:size]
    return data


def parse_td0(raw, verbose=False, log=print):
    if len(raw) < 12:
        raise TD0Error("file too short")
    hdr = raw[:12]
    sig = hdr[:2]
    if sig not in (b'TD', b'td'):
        raise TD0Error(f"bad signature {sig!r}")
    advanced = sig == b'td'
    seq, chk, ver, rate, dtype, stepping, dosalloc, sides = hdr[2:10]
    hcrc, = struct.unpack_from('<H', hdr, 10)
    info = {
        'advanced': advanced, 'version': ver, 'rate': rate & 0x7F,
        'fm': bool(rate & 0x80), 'drive': dtype, 'stepping': stepping & 3,
        'sides': sides, 'comment': None, 'date': None,
    }
    if td_crc(hdr[:10]) != hcrc:
        log("WARNING: header CRC mismatch")
    if seq != 0:
        raise TD0Error("multi-volume TD0 sets are not supported")

    if advanced:
        if ver < 20:
            raise TD0Error("Teledisk 1.x advanced compression (LZW) not supported")
        body = LZHUF(raw[12:]).decompress()
    else:
        body = raw[12:]

    p = 0
    if stepping & 0x80:
        ccrc, clen = struct.unpack_from('<HH', body, p)
        date = body[p + 4:p + 10]
        text = body[p + 10:p + 10 + clen]
        if td_crc(body[p + 2:p + 10 + clen]) != ccrc:
            log("WARNING: comment CRC mismatch")
        y, mo, d, h, mi, s = date
        info['date'] = f"{1900 + y:04d}-{mo + 1:02d}-{d:02d} {h:02d}:{mi:02d}:{s:02d}"
        info['comment'] = text.replace(b'\x00', b'\n').decode('latin-1').rstrip()
        p += 10 + clen

    tracks = []   # list of (cyl, head, [sectors])
    while True:
        if p >= len(body):
            log("WARNING: image ended without end-of-disk marker")
            break
        nsec = body[p]
        if nsec == 0xFF:
            break
        cyl, head, tcrc = body[p + 1], body[p + 2], body[p + 3]
        if td_crc(body[p:p + 3]) & 0xFF != tcrc:
            log(f"WARNING: track header CRC mismatch at C{cyl} H{head}")
        p += 4
        secs = []
        for _ in range(nsec):
            sc, sh, sid, scode, sflags, scrc = body[p:p + 6]
            p += 6
            size = 128 << scode if scode <= 6 else 0
            sec = {'c': sc, 'h': sh, 'id': sid, 'code': scode, 'flags': sflags,
                   'size': size, 'data': None, 'enc': None}
            if (sflags & 0x30) == 0 and scode <= 6:
                blen, = struct.unpack_from('<H', body, p)
                enc = body[p + 2]
                payload = body[p + 3:p + 2 + blen]
                p += 2 + blen
                sec['enc'] = enc
                sec['data'] = expand_sector(enc, payload, size)
                if td_crc(sec['data']) & 0xFF != scrc:
                    log(f"WARNING: sector CRC mismatch C{cyl} H{head} S{sid}")
            secs.append(sec)
        tracks.append((cyl, head & 1, secs))
    return info, tracks


def trim_tracks(tracks, cyls=None, log=print):
    """Drop cylinders >= cyls. With cyls=None, auto-trim trailing "overread"
    cylinders: tracks imaged beyond the end of the disk whose sector headers
    carry a different cylinder number (typical when a 40-track disk is read
    in an 80-track drive)."""
    if not tracks:
        raise TD0Error("no tracks found")
    if cyls is None:
        bad = {c for c, _, secs in tracks if secs and all(s['c'] != c for s in secs)}
        last = max(c for c, _, _ in tracks)
        top = last
        while top in bad:
            top -= 1
        if top < last:
            log(f"  trimming cylinders {top + 1}..{last} "
                f"(sector IDs don't match physical cylinder)")
        cyls = top + 1
    return [t for t in tracks if t[0] < cyls]


def build_raw(tracks, fill=0xE5, side_order=False, log=print):
    ncyl = max(c for c, _, _ in tracks) + 1
    nheads = max(h for _, h, _ in tracks) + 1

    # Determine the "standard" geometry: most common sector count & size
    from collections import Counter
    geo = Counter()
    for _, _, secs in tracks:
        good = [s for s in secs if s['size']]
        if good:
            geo[(len({s['id'] for s in good}), good[0]['size'],
                 min(s['id'] for s in good))] += 1
    (spt, ssize, first_id), _ = geo.most_common(1)[0]

    tmap = {(c, h): secs for c, h, secs in tracks}
    order = ([(c, h) for h in range(nheads) for c in range(ncyl)] if side_order
             else [(c, h) for c in range(ncyl) for h in range(nheads)])

    out = bytearray()
    problems = 0
    for c, h in order:
        secs = tmap.get((c, h), [])
        by_id = {}
        for s in secs:
            if s['id'] not in by_id or (by_id[s['id']]['data'] is None and s['data']):
                by_id[s['id']] = s   # keep first good copy of duplicated IDs
        for sid in range(first_id, first_id + spt):
            s = by_id.get(sid)
            if s is None or s['data'] is None:
                problems += 1
                log(f"  missing/no-data sector C{c} H{h} S{sid} -> filled 0x{fill:02X}")
                out += bytes([fill]) * ssize
            else:
                d = s['data']
                if len(d) != ssize:
                    log(f"  C{c} H{h} S{sid}: size {len(d)} != {ssize}, padded/truncated")
                    d = (d + bytes([fill]) * ssize)[:ssize]
                out += d
        extra = sorted(set(by_id) - set(range(first_id, first_id + spt)))
        if extra:
            log(f"  C{c} H{h}: extra sector IDs {extra} not written to raw image")
    return bytes(out), dict(cyls=ncyl, heads=nheads, spt=spt, size=ssize,
                            first_id=first_id, problems=problems)


# --------------------------------------------------------------------------
# EDSK writer
# --------------------------------------------------------------------------
# TD0 sector flags
TD_DUP, TD_CRCERR, TD_DELETED, TD_NOTALLOC, TD_NODATA = 0x01, 0x02, 0x04, 0x10, 0x20


def default_gap3(nsec, size, rate):
    """Pick a plausible format GAP3 so the u765 rotational timing matches a
    real drive (~6250 bytes/track at 250 kbps DD, 300 rpm)."""
    track_bytes = {0: 6250, 1: 6250, 2: 10416}.get(rate, 6250)
    if nsec == 0:
        return 0x4E
    g = (track_bytes - nsec * (size + 62)) // nsec
    return max(0x0A, min(0x4E, g))


def build_edsk(tracks, info, fill=0xE5, gap3=None, creator="td0conv.py", log=print):
    ncyl = max(c for c, _, _ in tracks) + 1
    nheads = max(h for _, h, _ in tracks) + 1
    tmap = {(c, h): secs for c, h, secs in tracks}

    blocks = []        # track blocks in file order
    sizes = []         # track size table (MSB, units of 256)
    for c in range(ncyl):
        for h in range(nheads):
            secs = tmap.get((c, h))
            if not secs:
                sizes.append(0)          # unformatted track
                blocks.append(b'')
                continue
            if len(secs) > 29:
                raise TD0Error(f"C{c} H{h}: {len(secs)} sectors (EDSK max 29)")
            tinfo = bytearray(256)
            tinfo[0:12] = b'Track-Info\r\n'
            tinfo[0x10] = c
            tinfo[0x11] = h
            tinfo[0x12] = 2 if info['rate'] == 2 else 1        # data rate: SD/DD or HD
            tinfo[0x13] = 1 if info['fm'] else 2               # recording mode FM/MFM
            codes = [s['code'] for s in secs]
            tinfo[0x14] = max(set(codes), key=codes.count)     # nominal N
            tinfo[0x15] = len(secs)
            tinfo[0x16] = gap3 if gap3 is not None else \
                default_gap3(len(secs), 128 << min(tinfo[0x14], 6), info['rate'])
            tinfo[0x17] = fill
            data = bytearray()
            for i, s in enumerate(secs):                       # physical order
                st1 = st2 = 0
                if s['flags'] & TD_NODATA or s['size'] == 0:
                    st1 |= 0x01; st2 |= 0x01                   # MA / MD: no data AM
                    payload = b''
                elif s['data'] is None:                        # not allocated
                    payload = bytes([fill]) * s['size']
                else:
                    payload = s['data']
                if s['flags'] & TD_CRCERR:
                    st1 |= 0x20; st2 |= 0x20                   # DE / DD: data CRC error
                if s['flags'] & TD_DELETED:
                    st2 |= 0x40                                # CM: deleted data AM
                o = 0x18 + i * 8
                tinfo[o:o + 8] = struct.pack('<6BH', s['c'], s['h'], s['id'],
                                             s['code'], st1, st2, len(payload))
                data += payload
            blk = bytes(tinfo) + bytes(data)
            blk += bytes(-len(blk) % 256)
            if len(blk) > 0xFF00:
                raise TD0Error(f"C{c} H{h}: track too big for EDSK")
            sizes.append(len(blk) // 256)
            blocks.append(blk)

    if len(sizes) > 204:
        raise TD0Error("too many tracks for the EDSK header")
    hdr = bytearray(256)
    hdr[0:34] = b'EXTENDED CPC DSK File\r\nDisk-Info\r\n'
    hdr[0x22:0x30] = creator.encode('ascii')[:14].ljust(14, b'\x00')
    hdr[0x30] = ncyl
    hdr[0x31] = nheads
    hdr[0x34:0x34 + len(sizes)] = bytes(sizes)
    img = bytes(hdr) + b''.join(blocks)
    return img, dict(cyls=ncyl, heads=nheads)


def main():
    ap = argparse.ArgumentParser(description="Convert Teledisk TD0 images to EDSK or raw")
    ap.add_argument('input')
    ap.add_argument('-o', '--output', help="output file (default: input name with .dsk/.img)")
    ap.add_argument('-f', '--format', choices=['edsk', 'raw'],
                    help="output format (default: edsk, or from the -o extension)")
    ap.add_argument('--gap3', type=lambda x: int(x, 0),
                    help="EDSK GAP3 value (default: computed from track geometry)")
    ap.add_argument('-v', '--verbose', action='store_true', help="dump track/sector map")
    ap.add_argument('--fill', type=lambda x: int(x, 0), default=0xE5,
                    help="fill byte for missing sectors (default 0xE5)")
    ap.add_argument('--side-order', action='store_true',
                    help="raw only: write all of side 0, then all of side 1")
    ap.add_argument('--cyls', type=int,
                    help="number of cylinders to write (default: auto, trims overread tracks)")
    a = ap.parse_args()

    raw = open(a.input, 'rb').read()
    info, tracks = parse_td0(raw, a.verbose)

    print(f"File      : {a.input}")
    print(f"Format    : {'Advanced (LZHUF)' if info['advanced'] else 'Normal'}, "
          f"Teledisk v{info['version'] // 10}.{info['version'] % 10}")
    print(f"Rate      : {DATA_RATES.get(info['rate'], info['rate'])} "
          f"{'FM' if info['fm'] else 'MFM'}, drive {DRIVE_TYPES.get(info['drive'], info['drive'])}, "
          f"sides {info['sides']}")
    if info['comment'] is not None:
        print(f"Date      : {info['date']}")
        print("Comment   : " + info['comment'].replace('\n', '\n            '))

    if a.verbose:
        for c, h, secs in tracks:
            ids = ' '.join(f"{s['id']:02X}{'' if s['data'] else '!'}" for s in secs)
            print(f"  C{c:02d} H{h} {len(secs):2d} sec: {ids}")

    fmt = a.format
    if fmt is None:
        fmt = 'raw' if a.output and a.output.lower().endswith(('.img', '.raw', '.bin')) else 'edsk'
    outname = a.output or a.input.rsplit('.', 1)[0] + ('.dsk' if fmt == 'edsk' else '.img')

    tracks = trim_tracks(tracks, a.cyls)
    if fmt == 'raw':
        img, g = build_raw(tracks, a.fill, a.side_order)
        print(f"Geometry  : {g['cyls']} cyl x {g['heads']} head x {g['spt']} sec x "
              f"{g['size']} bytes (first sector ID {g['first_id']})")
        extra = f", {g['problems']} sectors filled" if g['problems'] else ""
    else:
        img, g = build_edsk(tracks, info, a.fill, a.gap3)
        spt = {len(s) for _, _, s in tracks}
        print(f"Geometry  : {g['cyls']} cyl x {g['heads']} head, "
              f"{'/'.join(map(str, sorted(spt)))} sectors/track (physical order kept)")
        extra = ""
    with open(outname, 'wb') as f:
        f.write(img)
    print(f"Output    : {outname} [{fmt.upper()}] ({len(img)} bytes){extra}")

if __name__ == '__main__':
    try:
        main()
    except TD0Error as e:
        sys.exit(f"ERROR: {e}")
