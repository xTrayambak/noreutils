# do-not-compile

import std/[strutils, posix, os],
       ../norecore/[
          argparse,
          coreutil
        ]

type Du* = ref object of Coreutil

method showHelp*(du: Du) =
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

method execute*(du: Du): int =
  let
    humanReadable = du.arguments.isSwitchEnabled("human-readable", "h")
  0

when isMainModule:
  let du = Du(
    name: "du",
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

  du.run()
