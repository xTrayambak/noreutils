import std/[strutils, posix, os],
       ../norecore/[
          argparse,
          coreutil
        ]

type Cat* = ref object of Coreutil

method showHelp*(cat: Cat) =
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

proc controlCHook* {.noconv.} =
  quit 1

proc copyInputToOutput*(cat: Cat) =
  setControlCHook(controlCHook)
  while true:
    let line = readLine(stdin)
    stdout.write line & '\n'

    discard line

proc handle*(cat: Cat, target: string) =
  if dirExists(target):
    cat.error(target & ": Is a directory")

  if not fileExists(target):
    cat.error(target & ": No such file or directory")

  if access(target, R_OK) != 0:
    cat.error(target & ": Permission denied")

  var contents = readFile(target)
  let markEnds = cat.arguments.isSwitchEnabled("show-ends", "E")
  var n = 1

  if cat.arguments.isSwitchEnabled("show-tabs", "T"):
    contents = contents.replace("\t", "^I \b")

  let overrideNumberOpt = cat.arguments.isSwitchEnabled("number-nonblank", "b")

  if cat.arguments.isSwitchEnabled("number", "n") and not overrideNumberOpt:
    let splitted = contents.splitLines()
    for line in splitted:
      if n == splitted.len:
        continue

      stdout.write $n & '\t' & line
      
      if markEnds:
        stdout.write '$'

      if n < splitted.len:
        stdout.write '\n'

      inc n

    discard splitted
    discard n
  elif overrideNumberOpt:
    var n = 1
    let splitted = contents.splitLines()
    for line in splitted:
      if n == splitted.len:
        continue

      if line.len > 0:
        stdout.write $n & '\t' & line

        if markEnds:
          stdout.write '$'

        if n < splitted.len:
          stdout.write '\n'

        inc n
  else:
    if not markEnds:
      stdout.write contents & '\n'
    else:
      let splitted = contents.splitLines()
      var n = 1
      for line in splitted:
        if n == splitted.len:
          continue

        stdout.write line & '$'

        if n < splitted.len:
          stdout.write '\n'

method execute*(cat: Cat): int =
  if cat.arguments.isSwitchEnabled("help", "h"):
    cat.showHelp()

  if cat.arguments.isSwitchEnabled("credits", "C"):
    cat.showCredits()
  
  let targets = cat.arguments.getTargets()

  if targets.len < 1:
    cat.copyInputToOutput()

  for _, target in targets:
    cat.handle(target)

  0

when isMainModule:
  let cat = Cat(
    name: "cat",
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

  cat.run()
