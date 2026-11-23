#!/usr/bin/env python3
"""Construct signed Mach-O fixtures independently, then corrupt actual bytes."""
import hashlib
import importlib.util
import pathlib
import struct
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('package_verifier', ROOT / 'scripts/verify.py')
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)
HASHES = {1: ('sha1', 20), 2: ('sha256', 32), 3: ('sha256', 20), 4: ('sha384', 48)}


def hashed(data, kind):
    algorithm, size = HASHES[kind]
    return hashlib.new(algorithm, data).digest()[:size]


def directory(code, kind, requirement, page_shift=12, info=None):
    size = HASHES[kind][1]
    identifier = b'org.example.fixture\0'
    page_bytes = (1 << page_shift) if page_shift else len(code)
    pages = [code[start:start + page_bytes] for start in range(0, len(code), page_bytes)]
    offset = 88 + len(identifier) + size * 2
    length = offset + len(pages) * size
    header = struct.pack('>9I4BI', 0xfade0c02, length, 0x20400, 0, offset, 88, 2,
                         len(pages), len(code), size, kind, 0, page_shift, 0) + bytes(44)
    special = hashed(requirement, kind) + (hashed(info, kind) if info is not None else bytes(size))
    return header + identifier + special + b''.join(hashed(page, kind) for page in pages)


def signed_thin(subtype=0, kinds=(1, 2), page_shift=12, info=None):
    dataoff = 0x2100
    code = bytearray((index * 29 + 7) % 256 for index in range(dataoff))
    code[:32] = struct.pack('<8I', 0xfeedfacf, 0x0100000c, subtype, 6, 1, 16, 0, 0)
    requirement = struct.pack('>III', 0xfade0c01, 12, 0)

    def signature(content):
        entries = [(0 if i == 0 else 0x1000 + i - 1, directory(content, kind, requirement, page_shift, info))
                   for i, kind in enumerate(kinds)] + [(2, requirement)]
        offset = 12 + 8 * len(entries)
        indices, blobs, offsets = [], [], {}
        for slot, blob in entries:
            indices.append(struct.pack('>II', slot, offset))
            offsets[slot] = offset
            blobs.append(blob)
            offset += len(blob)
        raw = struct.pack('>III', 0xfade0cc0, offset, len(entries)) + b''.join(indices) + b''.join(blobs)
        return raw + bytes(-len(raw) % 16), offsets

    placeholder, _ = signature(code)
    code[32:48] = struct.pack('<4I', 0x1d, 16, dataoff, len(placeholder))
    embedded, offsets = signature(code)
    return bytes(code) + embedded, dataoff, len(embedded), offsets


def fat_binary():
    images = [signed_thin(0)[0], signed_thin(0x80000002)[0]]
    offset = 64
    entries, body = [], bytearray(bytes(64))
    for subtype, image in zip((0, 0x80000002), images):
        offset += -offset % 16
        if len(body) < offset:
            body.extend(bytes(offset - len(body)))
        entries.append(struct.pack('>5I', 0x0100000c, subtype, offset, len(image), 4))
        body.extend(image)
        offset += len(image)
    body[:48] = struct.pack('>2I', 0xcafebabe, 2) + b''.join(entries)
    return bytes(body)


class SignatureTests(unittest.TestCase):
    def valid(self, **kwargs):
        image, offset, size, _ = signed_thin(**kwargs)
        return verify.inspect_embedded_signature(image, offset, size, {1: kwargs['info']} if kwargs.get('info') else {})

    def corrupt(self, action, **kwargs):
        image, offset, size, entries = signed_thin(**kwargs)
        mutable = bytearray(image)
        action(mutable, offset, size, entries)
        with self.assertRaises(AssertionError):
            verify.inspect_embedded_signature(mutable, offset, size)

    def test_real_format_all_hash_algorithms(self):
        for kind in (1, 2, 3, 4):
            with self.subTest(kind=kind):
                result = self.valid(kinds=(kind, 2))
                self.assertEqual(len(result['codeDirectories']), 2)
                self.assertTrue(result['embeddedPageHashIntegrityVerified'])
                self.assertFalse(result['appleTrustVerified'])

    def test_entire_binary_single_page(self):
        self.assertEqual(self.valid(page_shift=0)['codeDirectories'][0]['pagesVerified'], 1)

    def test_external_info_hash_when_present(self):
        info = b'<plist><dict/></plist>'
        self.valid(info=info)
        image, offset, size, _ = signed_thin(info=info)
        with self.assertRaises(AssertionError):
            verify.inspect_embedded_signature(image, offset, size, {1: info + b'corrupt'})

    def test_macho_two_architecture_integration(self):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'Fixture.dylib'
            path.write_bytes(fat_binary())
            result = verify.inspect_macho(path)
            self.assertEqual(len(result['signatures']), 2)
            self.assertTrue(all(s['embeddedPageHashIntegrityVerified'] for s in result['signatures']))
            raw = bytearray(path.read_bytes())
            first_offset = struct.unpack_from('>I', raw, 16)[0]
            raw[first_offset + 100] ^= 1
            path.write_bytes(raw)
            with self.assertRaises(AssertionError):
                verify.inspect_macho(path)

    def test_corrupt_code_page(self):
        self.corrupt(lambda raw, off, size, entries: raw.__setitem__(5000, raw[5000] ^ 1))

    def test_corrupt_alternate_code_hash(self):
        def change(raw, off, size, entries):
            cd = off + entries[0x1000]
            hash_offset = struct.unpack_from('>I', raw, cd + 16)[0]
            raw[cd + hash_offset] ^= 1
        self.corrupt(change)

    def test_empty_placeholder_page_hashes(self):
        def change(raw, off, size, entries):
            cd = off + entries[0]
            hash_offset = struct.unpack_from('>I', raw, cd + 16)[0]
            raw[cd + hash_offset:cd + hash_offset + 20] = bytes(20)
        self.corrupt(change)

    def test_corrupt_requirements_blob(self):
        self.corrupt(lambda raw, off, size, entries: raw.__setitem__(off + entries[2] + 11, 1))

    def test_unvalidated_nonzero_special_slot(self):
        def change(raw, off, size, entries):
            cd = off + entries[0]
            hash_offset = struct.unpack_from('>I', raw, cd + 16)[0]
            raw[cd + hash_offset - 20] = 1
        self.corrupt(change)

    def test_missing_special_slot_digest(self):
        def change(raw, off, size, entries):
            cd = off + entries[0]
            hash_offset = struct.unpack_from('>I', raw, cd + 16)[0]
            raw[cd + hash_offset - 40:cd + hash_offset - 20] = bytes(20)
        self.corrupt(change)

    def test_sha1_only_rejected(self):
        image, offset, size, _ = signed_thin(kinds=(1,))
        with self.assertRaises(AssertionError):
            verify.inspect_embedded_signature(image, offset, size)

    def test_malformed_structures(self):
        mutations = {
            'empty_superblob': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + 8, 0),
            'out_of_bounds_index': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + 16, size + 1),
            'duplicate_slot': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + 20, 0),
            'overlapping_blob': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + 24, entries[0]),
            'unknown_blob': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + 28, 0x2222),
            'short_cd': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 4, 8),
            'unknown_version': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 8, 0x20601),
            'hash_size': lambda raw, off, size, entries: raw.__setitem__(off + entries[0] + 36, 19),
            'page_count': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 28, 99),
            'code_limit': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 32, off - 1),
            'page_shift': lambda raw, off, size, entries: raw.__setitem__(off + entries[0] + 39, 31),
            'identifier_bounds': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 20, 1),
            'scatter': lambda raw, off, size, entries: struct.pack_into('>I', raw, off + entries[0] + 44, 88),
            'wide_limit': lambda raw, off, size, entries: struct.pack_into('>Q', raw, off + entries[0] + 56, off + 1),
            'signature_padding': lambda raw, off, size, entries: raw.__setitem__(off + size - 1, 1),
        }
        for name, mutation in mutations.items():
            with self.subTest(name=name):
                self.corrupt(mutation)

    def test_truncated_input(self):
        image, offset, size, _ = signed_thin()
        with self.assertRaises(AssertionError):
            verify.inspect_embedded_signature(image[:-1], offset, size)


if __name__ == '__main__':
    unittest.main(verbosity=2)
