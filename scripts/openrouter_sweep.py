#!/usr/bin/env python3
"""Sample open-weight models on the benchmark prompts through OpenRouter.

    python3 scripts/openrouter_sweep.py --dry-run                 # plan + cost estimate
    python3 scripts/openrouter_sweep.py --samples 1 --models kimi31pro   # pilot
    python3 scripts/openrouter_sweep.py --samples 8               # full sweep

Needs OPENROUTER_API_KEY in the environment (never written anywhere).
Models and sampling settings live in experiments/openweights/models.json.

WHAT IS SENT: each task's probe/PASTE.md, byte for byte, as the only user
message -- the same text the published corpus answered. No system prompt, no
added instructions. A prompt that differs from the corpus's makes the scores
incomparable with it, which is the one thing this sweep must not do.

WHAT IS WRITTEN, per (task, model, sample), under experiments/openweights/<task>/:
  <model>__sNN.sv     the extracted answer, if one was found
  <model>__sNN.json   the raw response, usage, cost, provider, every parameter
                      sent, the prompt's sha256 and the task_text_hash
Outputs stay out of candidates/ on purpose: the corpus denominators are counted
from that directory, and this sweep must not move them.

RESUMABLE: a sample whose sidecar records a completed response is skipped, so
re-running after an interruption or a budget stop only fills the gaps. API
errors are retried on the next run.
"""
import argparse
import concurrent.futures as cf
import glob
import hashlib
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "scripts"))
OUT = os.path.join(REPO, "experiments", "openweights")
API = "https://openrouter.ai/api/v1/chat/completions"
DONE = {"ok", "no_code", "wrong_module", "truncated"}   # completed responses

# Withdrawn (no scoring testbench) or held out of the metrics by the owner.
SKIP = {"d_dsp01", "d_ca06"}


def yget(path, key, nested=False):
    """Top-level `key:`; or, with nested=True, an indented one -- verification
    tasks declare tb_module under `harness:`, which is where sim_verification.sh
    reads it from."""
    pat = (r"^[ \t]+%s:[ \t]*(\S+)" if nested else r"^%s:[ \t]*(\S+)") % re.escape(key)
    m = re.search(pat, open(path).read(), re.M)
    return m.group(1).strip("'\"") if m else None


def discover(include):
    """[(short, full, kind, expected_module, paste_path)] for every prompt."""
    try:
        from task_text_hash import task_text_hash
    except Exception:
        task_text_hash = None
    tasks = []
    for paste in sorted(glob.glob(os.path.join(REPO, "domains", "*", "*", "*", "probe", "PASTE.md"))):
        tdir = os.path.dirname(os.path.dirname(paste))
        full = os.path.basename(tdir)
        short = "_".join(full.split("_")[:2])
        if short in SKIP and short not in include:
            continue
        kind = "verification" if "/verification/" in tdir else "design"
        y = os.path.join(tdir, "task.yaml")
        mod = (yget(y, "tb_module", nested=True) if kind == "verification"
               else yget(y, "module"))
        if not mod:
            sys.exit(f"{full}: task.yaml has no {'tb_module' if kind == 'verification' else 'module'}")
        tth = None
        if task_text_hash:
            try:
                tth = task_text_hash(tdir)[0]
            except Exception:
                tth = None
        tasks.append(dict(short=short, full=full, kind=kind, module=mod,
                          paste=paste, task_text_hash=tth))
    return tasks


FENCE = re.compile(r"```[ \t]*([A-Za-z0-9_+.-]*)[ \t]*\r?\n(.*?)```", re.S)


def extract(text, module):
    """(status, code). Takes the LAST fenced block declaring the expected module
    -- a final answer usually follows drafts -- else the span from the first
    `module` to the last `endmodule` in unfenced text."""
    decl = re.compile(r"\bmodule\s+%s\b" % re.escape(module))
    blocks = [b for _lang, b in FENCE.findall(text or "")]
    hits = [b for b in blocks if decl.search(b)]
    if hits:
        return "ok", hits[-1].strip() + "\n"
    if blocks and any(re.search(r"\bmodule\s+\w+", b) for b in blocks):
        return "wrong_module", max(blocks, key=len).strip() + "\n"
    i, j = (text or "").find("module "), (text or "").rfind("endmodule")
    if i >= 0 and j > i:
        code = text[i:j + len("endmodule")].strip() + "\n"
        return ("ok" if decl.search(code) else "wrong_module"), code
    return "no_code", ""


def call(payload, key, timeout):
    req = urllib.request.Request(
        API, data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json",
                 "X-Title": "hw-rl-benchmark open-weight sweep"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())


class Budget:
    def __init__(self, cap):
        self.cap, self.spent, self.lock, self.stopped = cap, 0.0, threading.Lock(), False

    def add(self, usd):
        with self.lock:
            self.spent += usd or 0.0
            if self.cap is not None and self.spent >= self.cap:
                self.stopped = True

    def ok(self):
        return not self.stopped


def one(job, cfg, key, budget, timeout):
    t, tag, n = job["task"], job["model"], job["sample"]
    d = os.path.join(OUT, t["short"])
    os.makedirs(d, exist_ok=True)
    side = os.path.join(d, f"{tag}__s{n:02d}.json")
    if not budget.ok():
        return tag, t["short"], n, "skipped_budget", 0.0
    m = cfg["models"][tag]
    params = dict(cfg["defaults"], **m.get("params", {}))
    prompt = open(t["paste"], encoding="utf-8").read()
    payload = {"model": m["slug"], "messages": [{"role": "user", "content": prompt}],
               "usage": {"include": True}, **params}
    rec = {"task": t["full"], "task_short": t["short"], "kind": t["kind"],
           "model_tag": tag, "model_slug": m["slug"], "model_label": m.get("label"),
           "sample": n, "expected_module": t["module"],
           "prompt_sha256": hashlib.sha256(prompt.encode()).hexdigest(),
           "task_text_hash": t["task_text_hash"],
           "params_sent": {k: v for k, v in payload.items() if k not in ("messages",)},
           "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    # A PROVIDER THAT STOPS SHORT OF ITS LISTED CAP is routed around inside the
    # same run: the next hop ignores it. Without this, a capped sample waited for
    # a manual re-run -- which could land on the same provider again.
    cost, capped = 0.0, []
    for hop in range(3):
      resp, err = None, None
      for attempt in range(5):
          try:
              resp = call(payload, key, timeout)
              break
          except urllib.error.HTTPError as e:
              body = e.read().decode(errors="replace")[:500]
              err = f"HTTP {e.code}: {body}"
              if e.code not in (408, 429, 500, 502, 503, 504):
                  break                                   # a bad request will not improve
          except Exception as e:                          # timeouts, resets
              err = f"{type(e).__name__}: {e}"
          time.sleep(min(15 * 2 ** attempt, 240))
      rec["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
      if resp is None:
          rec.update(status="api_error", error=err)
      elif "error" in resp and not resp.get("choices"):
          rec.update(status="api_error", error=json.dumps(resp["error"])[:500])
      else:
          ch = (resp.get("choices") or [{}])[0]
          msg = ch.get("message") or {}
          content = msg.get("content") or ""
          status, code = extract(content, t["module"])
          usage = resp.get("usage") or {}
          if ch.get("finish_reason") == "length" and status != "ok":
              status = "truncated"
              # A PROVIDER CAP IS NOT THE MODEL RUNNING OUT OF ROOM. SiliconFlow
              # listed 262144 output tokens for GLM and stopped at 32768; scored as
              # truncated, that is a model failure caused by routing. Stopping well
              # short of the budget we asked for marks it, and it is retried.
              got, asked = usage.get("completion_tokens") or 0, params.get("max_tokens") or 0
              if asked and got < 0.9 * asked:
                  status = "provider_cap"
          # AN EMPTY, UNBILLED REPLY IS THE PROVIDER FAILING, NOT THE MODEL. Five
          # GLM answers in the first full sweep came back with no text at $0.0000
          # and were scored no_code -- a routing failure counted against the
          # model. Billed-but-codeless replies stay no_code: those are real.
          if not content.strip() and not float(usage.get("cost") or 0.0):
              status = "empty_response"
          # A STREAM THAT BROKE MID-ANSWER is the provider failing too: GMICloud
          # returned finish_reason "error" at 23k and 71k tokens, unbilled, with
          # half an answer that scored no_code. Retried whatever was extracted --
          # an answer cut mid-file says nothing about the model.
          if ch.get("finish_reason") == "error":
              status = "provider_error"
          cost += float(usage.get("cost") or 0.0)
          rec.update(status=status, finish_reason=ch.get("finish_reason"),
                     provider=resp.get("provider"), response_model=resp.get("model"),
                     response_id=resp.get("id"), usage=usage, content=content,
                     reasoning=msg.get("reasoning"))
          if code:
              sv = os.path.join(d, f"{tag}__s{n:02d}.sv")
              with open(sv, "w", encoding="utf-8") as fh:
                  fh.write(code)
              rec["sv"] = os.path.relpath(sv, REPO)
              rec["sv_sha256_16"] = hashlib.sha256(code.encode()).hexdigest()[:16]
      prov = rec.get("provider")
      if rec.get("status") != "provider_cap" or not prov or hop == 2:
          break
      capped.append(prov)
      pv = dict(payload.get("provider") or {})
      pv["ignore"] = sorted(set(pv.get("ignore", [])) | {prov})
      if "only" in pv:
          pv["only"] = [x for x in pv["only"] if x != prov]
          if not pv["only"]:
              break                                   # nowhere left to route
      payload["provider"] = pv
      rec["params_sent"]["provider"] = pv           # the routing that answered
      for k in ("sv", "sv_sha256_16", "error", "content", "reasoning", "usage"):
          rec.pop(k, None)
    if capped:
      rec["capped_providers"] = capped              # paid for, routed around
    rec["cost_usd"] = cost
    budget.add(cost)
    tmp = side + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(rec, fh, indent=1)
    os.replace(tmp, side)                               # never a half-written sidecar
    return tag, t["short"], n, rec["status"], cost


def done_already(t, tag, n):
    side = os.path.join(OUT, t["short"], f"{tag}__s{n:02d}.json")
    try:
        r = json.load(open(side))
    except Exception:
        return False
    # Sidecars written before provider_cap existed: re-judge a "truncated" one.
    if r.get("status") == "truncated":
        got = (r.get("usage") or {}).get("completion_tokens") or 0
        asked = (r.get("params_sent") or {}).get("max_tokens") or 0
        if asked and got < 0.9 * asked:
            return False
    # Sidecars written before provider_error existed: a broken stream.
    if r.get("finish_reason") == "error":
        return False
    # Sidecars written before empty_response existed: an unbilled empty reply.
    if r.get("status") == "no_code" and not (r.get("content") or "").strip() \
            and not float((r.get("usage") or {}).get("cost") or 0.0):
        return False
    return r.get("status") in DONE


def price_table():
    try:
        with urllib.request.urlopen("https://openrouter.ai/api/v1/models", timeout=30) as r:
            return {m["id"]: m.get("pricing", {}) for m in json.loads(r.read())["data"]}
    except Exception:
        return {}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--samples", type=int, default=3)
    ap.add_argument("--models", default="", help="comma-separated tags (default: all in models.json)")
    ap.add_argument("--tasks", default="", help="comma-separated task ids, e.g. d_ca01,v_ai02")
    ap.add_argument("--include", default="", help="also run normally-skipped tasks (d_ca06, d_dsp01)")
    ap.add_argument("--concurrency", type=int, default=6)
    ap.add_argument("--max-usd", type=float, default=None, help="stop launching requests past this spend")
    ap.add_argument("--timeout", type=int, default=1200, help="seconds per request")
    ap.add_argument("--est-out-tokens", type=int, default=20000, help="for --dry-run cost estimate")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        return selftest()
    cfg = json.load(open(os.path.join(OUT, "models.json")))
    tags = [x for x in a.models.split(",") if x] or list(cfg["models"])
    for x in tags:
        if x not in cfg["models"]:
            sys.exit(f"unknown model tag {x!r}; known: {', '.join(cfg['models'])}")
    tasks = discover(set(a.include.split(",")) if a.include else set())
    if a.tasks:
        want = set(a.tasks.split(","))
        tasks = [t for t in tasks if t["short"] in want]
    jobs = [dict(task=t, model=m, sample=n) for m in tags for t in tasks
            for n in range(1, a.samples + 1)]
    todo = [j for j in jobs if not done_already(j["task"], j["model"], j["sample"])]
    nd = sum(t["kind"] == "design" for t in tasks)
    print(f"tasks    : {len(tasks)} ({nd} design, {len(tasks) - nd} verification)")
    slugs = ", ".join(f"{x}={cfg['models'][x]['slug']}" for x in tags)
    print(f"models   : {slugs}")
    print(f"samples  : {a.samples} per task per model")
    print(f"requests : {len(jobs)} total, {len(todo)} still to do")

    if a.dry_run:
        prices = price_table()
        total = 0.0
        for x in tags:
            p = prices.get(cfg["models"][x]["slug"], {})
            pin, pout = float(p.get("prompt", 0)), float(p.get("completion", 0))
            n_x = sum(1 for j in todo if j["model"] == x)
            in_tok = sum(os.path.getsize(j["task"]["paste"]) // 4 for j in todo if j["model"] == x)
            usd = in_tok * pin + n_x * a.est_out_tokens * pout
            total += usd
            print(f"  {x:10s} {cfg['models'][x]['slug']:32s} {n_x:4d} req  ~${usd:8.2f}"
                  + ("" if p else "   (price unknown)"))
        print(f"  estimated total ~${total:.2f}  (assumes {a.est_out_tokens} output tokens per answer,"
              f" reasoning included -- reasoning-heavy runs can exceed this)")
        return 0

    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        sys.exit("OPENROUTER_API_KEY is not set")
    budget = Budget(a.max_usd)
    counts = {}
    with cf.ThreadPoolExecutor(max_workers=a.concurrency) as ex:
        futs = [ex.submit(one, j, cfg, key, budget, a.timeout) for j in todo]
        for k, f in enumerate(cf.as_completed(futs), 1):
            tag, short, n, status, cost = f.result()
            counts[status] = counts.get(status, 0) + 1
            print(f"[{k:4d}/{len(todo)}] {tag:10s} {short:8s} s{n:02d}  {status:14s}"
                  f" ${cost:.4f}   spent ${budget.spent:.2f}", flush=True)
    print("\nsummary:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())),
          f"| spent ${budget.spent:.2f}")
    if budget.stopped:
        print(f"STOPPED at the --max-usd cap; re-run to continue where it left off.")
    return 0


def selftest():
    cases = [
        ("```systemverilog\nmodule foo(input a);\nendmodule\n```", "foo", "ok"),
        ("draft:\n```sv\nmodule foo(); endmodule\n```\nfinal:\n```verilog\nmodule foo(input b);\nendmodule\n```",
         "foo", "ok"),
        ("```sv\nmodule bar(); endmodule\n```", "foo", "wrong_module"),
        ("Here it is:\nmodule foo(input a);\n  assign x = a;\nendmodule\nDone.", "foo", "ok"),
        ("I cannot do that.", "foo", "no_code"),
        ("```sv\nmodule foo_tb; endmodule\n```", "foo", "wrong_module"),   # prefix must not match
    ]
    bad = 0
    for text, mod, want in cases:
        got, code = extract(text, mod)
        ok = got == want and (want != "ok" or "input b" in code or "draft" not in text)
        bad += not ok
        print(f"  {'ok ' if ok else 'BAD'} want={want:13s} got={got}")
    last = extract(cases[1][0], "foo")[1]
    if "input b" not in last:
        bad += 1; print("  BAD last-block rule: took the draft, not the final answer")
    print("selftest:", "PASS" if not bad else f"{bad} FAILED")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
