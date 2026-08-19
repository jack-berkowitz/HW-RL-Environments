#!/usr/bin/env python3
"""Write ONE immutable run record.

WHY THIS EXISTS
---------------
`collect_results.py` used to read the live ORFS output directory, which is
mutable, shared, and rewritten by any concurrent build. During an Fmax sweep the
d_nw01 row read `DID NOT COMPLETE` -- and `DID NOT COMPLETE` also happens to be
the genuine finding about that task's candidate. **A stale entry that
coincidentally matches a real result is the most dangerous form of this defect:
it would have gone into a writeup and nobody would have caught it, because it
looks right.**

The fix is structural rather than a lock. Every run writes an append-only record
keyed by task, submission identity (path AND content hash), timestamp and git
SHA. Collection reads only these records. If a record is absent, collection
reports it absent -- it never falls back to reading whatever is on disk.

A missing row is honest. A stale row is not.

Records live in runs/<task>/<utc>__<label>__<kind>.json and are never rewritten:
a second run of the same submission produces a second record, so the history of
what was measured when is recoverable. `collect_results.py` shows the newest per
(task, submission) and can show all of them.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def git_sha():
    try:
        out = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"],
                             capture_output=True, text=True, timeout=10)
        sha = out.stdout.strip()
        dirty = subprocess.run(["git", "-C", REPO, "status", "--porcelain"],
                               capture_output=True, text=True, timeout=10).stdout.strip()
        return (sha + ("-dirty" if dirty else "")) if sha else "unknown"
    except Exception:
        return "unknown"


def sha256(path):
    try:
        with open(path, "rb") as fh:
            return hashlib.sha256(fh.read()).hexdigest()[:16]
    except OSError:
        return "unknown"


def parse_sim(raw_dir):
    """Per-config verdicts, METRIC lines and coverage lines from raw output."""
    configs, metrics, coverage = [], {}, {}
    if not os.path.isdir(raw_dir):
        return configs, metrics, coverage
    for fn in sorted(os.listdir(raw_dir)):
        if not fn.endswith(".txt"):
            continue
        cfg = fn[:-4]
        txt = open(os.path.join(raw_dir, fn), errors="replace").read()
        m = re.search(r"TEST_RESULT: (PASS|FAIL)", txt)
        verdict = m.group(1) if m else "NO_VERDICT"
        if "COMPILE_ERROR" in txt:
            verdict = "COMPILE"
        elif verdict == "PASS" and "COVERAGE HOLE" in txt:
            verdict = "HOLES"
        configs.append({"config": cfg.replace("__", " "), "verdict": verdict})
        # METRIC: name=value [name=value ...]   and   METRIC: free text
        for line in txt.splitlines():
            line = line.strip()
            if line.startswith("METRIC:"):
                body = line[len("METRIC:"):].strip()
                # A METRIC line may be `name=value ...` OR `name k=v k=v ...`,
                # where the leading bare identifier NAMES the metric and the
                # pairs are its fields. The second form was dropping the name
                # entirely and filing min/max/n under those generic keys, where
                # any other metric using the same field names would overwrite
                # them. d_ca04's crossing_latency_rdclk was measured, printed,
                # and then lost in the reporting path for exactly that reason --
                # it read ABSENT in the results table while being emitted on
                # every one of 18 configs.
                m0 = re.match(r"([A-Za-z_][A-Za-z0-9_]*)(?![\w]*=)\s+", body)
                prefix = f"{m0.group(1)}_" if m0 else ""
                for k, v in re.findall(r"([A-Za-z_][A-Za-z0-9_]*)=(-?[\w.]+)", body):
                    metrics.setdefault(cfg, {})[f"{prefix}{k}"] = v
                if prefix:
                    # keep the bare name addressable on its own
                    metrics.setdefault(cfg, {}).setdefault(prefix[:-1], "see fields")
            elif line.startswith("// coverage:"):
                body = line[len("// coverage:"):].strip()
                for k, v in re.findall(r"([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(-?[\w. ]+?)(?=\s+[A-Za-z_]+\s*=|$)", body):
                    coverage.setdefault(cfg, {})[k] = v.strip()
    return configs, metrics, coverage


def main():
    if len(sys.argv) < 5:
        sys.exit("usage: write_run_record.py <task> <submission> <kind> <label> "
                 "[raw_dir | key=value ...]")
    task, submission, kind, label = sys.argv[1:5]
    rest = sys.argv[5:]

    rec = {
        "task": task,
        "submission": os.path.relpath(submission, REPO) if submission.startswith(REPO) else submission,
        "submission_sha256_16": sha256(submission),
        "label": label,
        "kind": kind,                       # "sim" | "ppa"
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "git_sha": git_sha(),
    }

    # POSITION-INDEPENDENT. This used to be `os.path.isdir(rest[0])`, which
    # assumed the raw directory was the FIRST trailing argument. Inserting
    # `task_text_hash=...` ahead of it moved the directory to rest[1], the
    # isdir() test silently failed, and every design sim record written after
    # that carried no verdict at all -- 45 of them. The record was well-formed
    # and empty, which is worse than absent: it looks like a measurement.
    #
    # Two changes. Split on shape rather than position, and apply BOTH the
    # parsed verdict and the key/values -- this was an if/else, so a caller
    # could never pass a raw directory AND a task_text_hash, which is exactly
    # what sim_candidate.sh was trying to do.
    kvs = [a for a in rest if "=" in a]
    positionals = [a for a in rest if "=" not in a]

    for kv in kvs:
        k, v = kv.split("=", 1)
        rec[k] = v

    if kind == "sim":
        # REFUSE rather than skip. A writer that cannot find the raw directory
        # it was handed must fail loudly; emitting a record it could not
        # populate is the defect class, not just this instance of it.
        if len(positionals) > 1:
            sys.exit("write_run_record: %d positional arguments %r -- expected at "
                     "most one raw directory. Refusing to guess which is the "
                     "raw output; nothing written." % (len(positionals), positionals))
        if positionals:
            raw = positionals[0]
            if not os.path.isdir(raw):
                sys.exit("write_run_record: raw directory %r does not exist or is "
                         "not a directory. A sim record without its raw output "
                         "carries no verdict, and a well-formed empty record is "
                         "worse than none; nothing written." % raw)
            configs, metrics, coverage = parse_sim(raw)
            if not configs:
                sys.exit("write_run_record: raw directory %r contains no parseable "
                         "config output. Refusing to write a record with an empty "
                         "verdict; nothing written." % raw)
            passed = sum(1 for c in configs if c["verdict"] == "PASS")
            rec.update({
                "configs_total": len(configs),
                "configs_passed": passed,
                "all_passed": bool(configs) and passed == len(configs),
                "per_config": configs,
                "metrics": metrics,
                "coverage": coverage,
            })
        elif not kvs:
            # No raw directory AND no key/values: there is nothing to record.
            # (A verification-style call passes kvs and no raw dir -- legal.)
            sys.exit("write_run_record: sim record with neither a raw directory "
                     "nor any key=value fields. Nothing to write.")

    out_dir = os.path.join(REPO, "runs", task)
    os.makedirs(out_dir, exist_ok=True)
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", label)
    path = os.path.join(out_dir, f"{rec['timestamp_utc'].replace(':', '')}__{safe}__{kind}.json")
    # Never overwrite: records are append-only history.
    n = 1
    while os.path.exists(path):
        path = path[:-5] + f".{n}.json"
        n += 1
    with open(path, "w") as fh:
        json.dump(rec, fh, indent=2, sort_keys=True)
    print(os.path.relpath(path, REPO))


if __name__ == "__main__":
    main()
