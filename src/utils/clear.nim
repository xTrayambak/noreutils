#

import std/terminal,
       ../norecore/coreutil

type Clear* = ref object of Coreutil

method execute*(clear: Clear): int =
  stdout.eraseScreen()
  stdout.setCursorPos(0, 0)
  0

when isMainModule:
  let clear = Clear()

  clear.run()
