# do-not-compile

import std/[terminal],
       ../norecore/[
          argparse,
          coreutil
        ]

type Clear* = ref object of Coreutil

method execute*(clear: Clear): int =
  stdout.eraseScreen()
  stdout.setCursorPos(0, 0)
  0

when isMainModule:
  let clear = Clear(
    name: "clear",
    authors: @[
      Author(
        firstName: "Trayambak",
        middleName: "Mentally Insane",
        lastName: "Rai",

        middleNameInQuotations: true
      )
    ],
    arguments: parseArguments()
  )

  clear.run()
