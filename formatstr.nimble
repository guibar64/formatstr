# Package 
version       = "0.2.1"
author        = "G. Bareigts"
description   = "string interpolation, complement of std/strformat for runtime strings"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires: "nim >= 1.6.0"


# Tests
task test, "Runs tests":
  exec "nim c -r --verbosity:0 tests/test0.nim"
