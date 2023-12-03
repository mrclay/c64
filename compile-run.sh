#!/bin/bash

set -euo pipefail

BASENAME=${1:-test}

acme --msvc -f cbm --cpu 6510 -o "${BASENAME}.prg" "${BASENAME}.asm" && x64sc "${BASENAME}.prg"
