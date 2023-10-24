# Package

version       = "0.1.0"
author        = "xTrayambak"
description   = "Coreutils but dumber"
license       = "GPL-2.0-only"
srcDir        = "src"
bin           = @["noreutils"]


# Dependencies

requires "nim >= 1.6.14"
requires "pretty"
requires "nimAesCrypt"
