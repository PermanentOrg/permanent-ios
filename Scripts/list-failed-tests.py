#!/usr/bin/env python3
# Prints one GitHub ::error line per failure from the fastlane test log, with the failed test's name
# read from the result bundle, because the log line gives only the file and line.
# Usage: list-failed-tests.py <fastlane log> [<.xcresult>]

import json
import os
import re
import subprocess
import sys


def log_errors(log_path):
    workspace = os.environ.get("GITHUB_WORKSPACE", "")
    with open(log_path, errors="replace") as log:
        text = re.sub(r"\x1b\[[0-9;]*m", "", log.read())
    lines = []
    for match in re.finditer(r"::error .*", text):
        line = match.group(0)
        if workspace:
            line = line.replace(workspace + "/", "")
        if line not in lines:
            lines.append(line)
    return lines


def bundle_failures(bundle_path):
    if not bundle_path or not os.path.isdir(bundle_path):
        return []
    result = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", bundle_path, "--compact"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return []
    try:
        return json.loads(result.stdout).get("testFailures", [])
    except json.JSONDecodeError:
        return []


def first_line(text):
    return (text or "").strip().splitlines()[0].strip() if (text or "").strip() else ""


def find_test(line, failures, used):
    file_match = re.match(r"::error file=([^,]*)", line)
    stem = os.path.splitext(os.path.basename(file_match.group(1)))[0] if file_match else ""
    message = line.split("::", 2)[-1]
    for index, failure in enumerate(failures):
        if index in used:
            continue
        name = failure.get("testIdentifierString") or failure.get("testName", "")
        reason = first_line(failure.get("failureText"))
        if reason and reason in message and (not stem or name.startswith(stem + "/")):
            return index
    for index, failure in enumerate(failures):
        if index in used:
            continue
        reason = first_line(failure.get("failureText"))
        if reason and reason in message:
            return index
    return None


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: list-failed-tests.py <fastlane log> [<.xcresult>]")
    failures = bundle_failures(sys.argv[2] if len(sys.argv) > 2 else None)
    used = set()
    for line in log_errors(sys.argv[1]):
        index = find_test(line, failures, used)
        if index is None:
            print(line)
            continue
        used.add(index)
        failure = failures[index]
        _, kind, message = line.split("::", 2)
        head = "::" + kind
        name = failure.get("testIdentifierString") or failure.get("testName", "")
        print(f"{head}::{name}: {message.strip()}")
    for index, failure in enumerate(failures):
        if index not in used:
            name = failure.get("testIdentifierString") or failure.get("testName", "")
            print(f"::error::{name}: {first_line(failure.get('failureText'))}")


if __name__ == "__main__":
    main()
