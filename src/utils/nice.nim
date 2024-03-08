# do-not-compile

import std/[strutils, posix, os],
       ../norecore/[
          argparse,
          coreutil,
          ppriority
        ]

type Nice* = ref object of Coreutil

method showHelp*(nice: Nice) =
  echo """
Usage: cat [options] [targets]
Concatenate FILE(s) to standard output.

With no FILE, read standard input and copy it to standard output.

  --help -h             display this message
  -b, --number-nonblank number nonempty output lines, overrides -n
  -E, --show-ends       display $ at end of each line
  -n, --number          number all output lines
  -T, --show-tabs       display TAB characters as ^I

Examples:
  cat f g   Output f's contents, then g's contents
  cat       Copy standard input to standard output until interrupted via CTRL+C

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

method execute*(nice: Nice): int =
  if nice.arguments.isSwitchEnabled("help", "h"):
    nice.showHelp()
  
  if nice.arguments.isSwitchEnabled("credits", "c"):
    nice.showCredits()

  let targets = nice.arguments.getTargets()

  0

when isMainModule:
  let nice = Nice(
    name: "nice",
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

  nice.run()
