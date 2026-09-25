#!/usr/bin/env bash
# Free space on / in GB, formatted like theme 4 ("9.45 GB").
df -B1 --output=avail / | tail -1 | awk '{printf "%.2f GB\n", $1 / 1024 / 1024 / 1024}'
