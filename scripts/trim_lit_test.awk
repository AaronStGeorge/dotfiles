#!/usr/bin/env -S awk -f

# Little awk file to make life easier when dealing with large llvm lit tests.
# This script slices out everything except the top level `// RUN:` lines and
# anything between `//<TACO>` and `//</TACO>`. `cat` through this script to
# run a smaller input through `mlir-opt`, or extract a smaller lit test from 
# a larger one.
#
# Example: `cat big.mlir | trim_lit_test | mlir-opt -split-input-file -some-pass`

# If a line begins with "//<TACO>" set inside=1
/^\/\/<TACO>/ {inside=1; next;}

# If a line begins with "//</TACO>" set inside=0
/^\/\/<\/TACO>/ {inside=0; next;}

# If a line begins with "// RUN" print it
/^\/\/[[:space:]]*RUN/ {print;}

# If inside is truthy print the line
inside {print;}
