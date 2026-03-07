#!/bin/bash
# VRAM Monitor Script

echo "[Monitor] VRAM Monitoring started."

while true; do
  VRAM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null || echo "0")
  VRAM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null || echo "100")
  
  if [ "$VRAM_TOTAL" -eq "0" ]; then
    VRAM_PERCENT=0
  else
    VRAM_PERCENT=$((VRAM_USED * 100 / VRAM_TOTAL))
  fi

  if [ "$VRAM_PERCENT" -gt 75 ]; then
    MSG="[WARNING] VRAM usage: ${VRAM_PERCENT}% (${VRAM_USED}MB / ${VRAM_TOTAL}MB) - Critical Threshold Exceeded"
    echo "$MSG" | logger -t sunshine-vram
    echo "$MSG"
  fi
  sleep 60
done
