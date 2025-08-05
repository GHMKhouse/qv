# Package

version       = "0.1.0"
author        = "Anonymous"
description   = "A new awesome nimble package"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["qv"]


# Dependencies

requires "nim >= 2.2.4"
requires "nimgl >= 1.3.2"
requires "glm >= 1.1.1"
requires "sdl2 >= 2.0.5"
requires "stbimage >= 2.5"