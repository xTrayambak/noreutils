import std/[os, strutils, base64],
       ../norecore/[
argparse,
          coreutil
        ]

type
  Clear* = ref object of Coreutil

method execute*(clear: Clear): int =
  echo "\u001b[2J"
  
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
    ]
  )

  clear.run()
