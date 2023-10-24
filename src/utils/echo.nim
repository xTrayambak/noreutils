# do-not-compile

import ../norecore/[
          argparse,
          coreutil
        ]

type Echo* = ref object of Coreutil

proc controlCHook* {.noconv.} =
  quit 1

method execute*(echo: Echo): int =
  echo "Work in progress."

  1

  #[ let targets = echo.arguments.getTargets()

  if targets.len < 1:
    stdout.write '\n'
  
  var final = ""

  for _, target in targets:
    final &= target & ' ' 

  stdout.write final
  
  0 ]#

when isMainModule:
  let echo = Echo(
    name: "echo",
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

  echo.run()
