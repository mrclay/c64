#!/bin/bash

set -euo pipefail

BASENAME=${1:-test}

java -jar /Users/steve/KickAssembler/KickAss.jar "${BASENAME}.asm" && x64sc "${BASENAME}.prg"

