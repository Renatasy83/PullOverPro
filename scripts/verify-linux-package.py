#!/usr/bin/env python3
"""Inspect rootless Mach-O slices and modern arm64e ABI, without running iOS code."""
import io
import json
from pathlib import Path
import struct
import subprocess
import sys
import tarfile

package = Path(sys.argv[1])
payload = subprocess.check_output(["dpkg-deb", "--fsys-tarfile", str(package)])
seen = {}
with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
    for member in archive:
        if not member.isfile():
            continue
        name = member.name.removeprefix("./")
        data = archive.extractfile(member).read()
        if data[:4] != b"\xca\xfe\xba\xbe":
            continue
        if not name.startswith("var/jb/"):
            raise SystemExit("Binary outside rootless prefix")
        count = struct.unpack_from(">I", data, 4)[0]
        assert count == 2, (name, "expected exactly arm64 and arm64e")
        architectures = []
        for index in range(count):
            cpu, subtype, offset, size, _ = struct.unpack_from(">IIIII", data, 8 + index * 20)
            assert cpu == 0x0100000c and offset + size <= len(data)
            image = data[offset:offset + size]
            magic, image_cpu, image_subtype, _, commands, command_bytes, _, _ = struct.unpack_from("<8I", image)
            assert magic == 0xfeedfacf and image_cpu == cpu and image_subtype == subtype
            assert subtype in (0, 0x80000002), (name, hex(subtype), "incompatible arm64e ABI")
            cursor = 32
            signature = False
            assert command_bytes <= len(image) - 32
            for _ in range(commands):
                command, length = struct.unpack_from("<II", image, cursor)
                assert length >= 8 and cursor + length <= 32 + command_bytes
                if command == 0x1d:  # LC_CODE_SIGNATURE: presence/bounds, not trust or runtime validation.
                    signature_offset, signature_size = struct.unpack_from("<II", image, cursor + 8)
                    assert signature_size > 0 and signature_offset + signature_size <= len(image)
                    signature = True
                cursor += length
            assert cursor == 32 + command_bytes and signature, (name, "missing bounded code signature")
            if name.endswith("PPOMessengerReturnAgent.dylib"):
                for marker in (b"_notify_set_state\0", b"setWindowScene:\0", b"restoreAfterDisconnect:\0",
                               b"com.renatasy83.ppo.messenger.return.v5\0",
                               b"741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30\0",
                               b"354b8abc3acd00ae3a16f48e3b0156f1497be49742f6dc1db3753c13bbc89b9f\0"):
                    assert marker in image, (name, marker)
                for marker in (b"makeKeyWindow\0", b"makeKeyAndVisible\0", b"becomeFirstResponder\0", b"setRootViewController:\0"):
                    assert marker not in image, (name, "forbidden selector", marker)
            if name.endswith("PullOverProDiagnostic.dylib"):
                assert b"_notify_get_state\0" in image
                assert b"com.renatasy83.ppo.messenger.return.v5\0" in image
            assert b"com.renatasy83.ppo.messenger.return.v4\0" not in image
            assert b"com.renatasy83.ppo.messenger.return.prepare.v4\0" not in image
            assert b"PPO_BRIDGE_TEST_PATH" not in image
            architectures.append(hex(subtype))
        assert set(architectures) == {"0x0", "0x80000002"}
        seen[name] = architectures
assert len(seen) == 6, ("expected tweak, companion, three tools and preferences", seen)
print(json.dumps({"checkedBinaries": seen, "runtimeTest": False, "signatureTrustVerified": False}, indent=2))
