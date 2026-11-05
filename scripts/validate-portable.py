#!/usr/bin/env python3
"""Run existing portable fixtures; this does not replace macOS/UIKit tests."""
import argparse
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--compiler", default="g++")
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
args.output.mkdir(parents=True, exist_ok=True)
results = []
for source in sorted((root / "tests").glob("*.cpp")):
    binary = args.output / source.stem
    command = [args.compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror",
               "-fsanitize=address,undefined", str(source)]
    if source.stem == "BridgeIOTests":
        command.append(str(root / "PPOBridgeIO.cpp"))
    command.extend(["-o", str(binary.resolve())])
    compiled = subprocess.run(command, capture_output=True, text=True)
    executed = None
    if compiled.returncode == 0:
        executed = subprocess.run([str(binary.resolve())], capture_output=True, text=True)
    log = compiled.stdout + compiled.stderr
    if executed is not None:
        log += executed.stdout + executed.stderr
    (args.output / (source.stem + ".log")).write_text(log)
    result = {"suite": source.stem, "compileExit": compiled.returncode,
              "testExit": executed.returncode if executed is not None else None}
    results.append(result)
    print(json.dumps(result), flush=True)
(args.output / "portable-results.json").write_text(json.dumps(results, indent=2) + "\n")
if len(results) != 13 or any(r["compileExit"] != 0 or r["testExit"] != 0 for r in results):
    raise SystemExit("Portable fixtures failed or suite inventory changed; inspect logs")
print("Portable suites passed: 13; macOS Objective-C/UIKit execution not performed")
