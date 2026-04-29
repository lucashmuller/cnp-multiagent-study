#!/usr/bin/env python3
"""
Parse [METRIC] lines from CNP output and print a summary.

Usage:
    ./gradlew run 2>&1 | python3 ../metrics.py
    ./gradlew run 2>&1 | tee run.log && python3 ../metrics.py < run.log
"""

import sys
import re
from collections import defaultdict
from statistics import mean, median

records = []

for line in sys.stdin:
    if "[METRIC]" not in line:
        continue
    kv = dict(re.findall(r'(\w+)=(\S+)', line.split("[METRIC]", 1)[1]))
    if not kv:
        continue
    kv["proposals"] = int(kv.get("proposals", 0))
    kv["price"] = int(kv.get("price", 0)) if "price" in kv else None
    kv["elapsed_ms"] = int(kv.get("elapsed_ms", 0))
    records.append(kv)

if not records:
    print("No [METRIC] lines found. Run with: ./gradlew run 2>&1 | python3 ../metrics.py")
    sys.exit(1)

total = len(records)
done = [r for r in records if r["result"] == "done"]
fail = [r for r in records if r["result"] == "fail"]
timeout = [r for r in records if r["result"] == "timeout"]

print(f"\n{'='*50}")
print(f"  CNP Metrics Summary  ({total} contracts)")
print(f"{'='*50}")
print(f"  Success (done)  : {len(done):>4}  ({100*len(done)/total:.1f}%)")
print(f"  No bids (fail)  : {len(fail):>4}  ({100*len(fail)/total:.1f}%)")
print(f"  Timeout         : {len(timeout):>4}  ({100*len(timeout)/total:.1f}%)")

if done:
    prices = [r["price"] for r in done]
    elapsed = [r["elapsed_ms"] for r in done]
    print(f"\n--- Winning Price (done contracts) ---")
    print(f"  min={min(prices)}  max={max(prices)}  mean={mean(prices):.1f}  median={median(prices):.1f}")

    print(f"\n--- End-to-end Latency ms (done) ---")
    print(f"  min={min(elapsed)}  max={max(elapsed)}  mean={mean(elapsed):.1f}  median={median(elapsed):.1f}")

    print(f"\n--- Proposals per contract ---")
    props = [r["proposals"] for r in records if r["proposals"] > 0]
    if props:
        print(f"  min={min(props)}  max={max(props)}  mean={mean(props):.2f}")

    print(f"\n--- Results by service type ---")
    by_svc = defaultdict(list)
    for r in records:
        by_svc[r["service"]].append(r)
    for svc, rs in sorted(by_svc.items()):
        d = [r for r in rs if r["result"] == "done"]
        p = [r["price"] for r in d if r["price"]]
        print(f"  {svc:<12} total={len(rs)} done={len(d)} avg_price={mean(p):.1f}" if p else
              f"  {svc:<12} total={len(rs)} done={len(d)} avg_price=n/a")

    print(f"\n--- Winner frequency (strategy proxy) ---")
    winner_counts = defaultdict(int)
    for r in done:
        winner_counts[r["winner"]] += 1
    for agent, count in sorted(winner_counts.items(), key=lambda x: -x[1]):
        print(f"  {agent:<8} won {count:>3} contract(s)")

print()
