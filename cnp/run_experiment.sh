#!/usr/bin/env bash
# Usage: ./run_experiment.sh <label> <run_seconds>
# Example: ./run_experiment.sh "n5_m10_i3" 25
set -e

LABEL="${1:-run}"
WAIT="${2:-25}"
LOG="results/${LABEL}.log"
SUMMARY="results/${LABEL}_summary.txt"

mkdir -p results

echo "=== Running: $LABEL (${WAIT}s) ==="
timeout "$WAIT" ./gradlew run >"$LOG" 2>&1 || true

echo "=== Metrics for: $LABEL ===" | tee "$SUMMARY"
python3 metrics.py < "$LOG" | tee -a "$SUMMARY"
echo ""
