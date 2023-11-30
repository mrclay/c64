#!/bin/bash

set -euo pipefail

java -jar /Users/steve/KickAssembler/KickAss.jar test.asm && x64sc test.prg
