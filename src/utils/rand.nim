#

import std/[os, strutils, base64, options, random],
       ../norecore/[
          argparse,
          coreutil
        ]

type
  RandMode* = enum
    RandInvalid
    RandInt
    RandChoice

  Rand* = ref object of Coreutil

method showHelp*(rand: Rand) =
  echo """
Usage: rand [mode] [targets]
Everything to do with random numbers.

  --help, -h                display this message
  --number                  the number of choices to be selected or numbers to be generated, 
                            if more than one, then the choices will be outputted separated by a newline each (default = 1)
  --eliminate-redundant, -e whether to eliminate redundant choices (default = false)
  --dont-randomize, -d      don't call `randomize` before generating numbers (default = false)

Examples:
  rand int 10-20 # Generate a random number between 10 to 20
  rand choice linux windows macOS # choose between "linux", "windows", "macOS"

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

proc tryParseInt*(s: string): Option[int] {.inline, raises: [].} =
  try:
    if s.len < 1:
      return some(1)

    return some(parseInt(s))
  except ValueError:
    return none(int)

proc choices*(util: Rand) =
  let targets = util.arguments.getTargets()

  if targets.len < 3:
    util.error("only one (or none) arguments provided for random selection!")

  var outcomes: seq[string]

  for i, target in targets[1..targets.len-1]:
    outcomes.add(target)

  let
    noRedundant = util.arguments.isSwitchEnabled("eliminate-redundant", "e")
    number = util.arguments.getFlag("number").tryParseInt()

  if not number.isSome:
    util.error("invalid number passed for --number argument!")

  let no = unsafeGet(number)

  if no < 1:
    util.error("--number cannot be less than 0!")
  
  if noRedundant and no > outcomes.len-1:
    util.error("--number cannot be greater than the number of choices provided if --eliminate-redundant is enabled!")

  var output: seq[string]

  while output.len-1 < no-1:
    let attempt = sample(outcomes)
    
    if attempt in output and noRedundant:
      continue

    output.add(attempt)

  for o in output:
    stdout.write o & '\n'

proc randint*(util: Rand) =
  let targets = util.arguments.getTargets()

  if targets.len < 2:
    util.error("no range specified for random number generation!")

  let 
    nrange = targets[1]
    splitted = nrange.split('-')

  if splitted.len < 2:
    util.error("invalid range provided!")

  let
    olo = splitted[0].tryParseInt()
    ohi = splitted[1].tryParseInt()
  
  if olo.isNone:
    util.error("invalid integer provided for lower value")

  if ohi.isNone:
    util.error("invalid integer provided for higher value")

  let 
    lo = unsafeGet olo
    hi = unsafeGet ohi

  if lo >= hi:
    util.error("lower value cannot be equal or greater than higher value!")

  let number = util.arguments.getFlag("number").tryParseInt()

  if number.isNone:
    util.error("invalid number passed for --number argument!")

  let no = unsafeGet(number)

  if no == 0:
    return

  for x in 0..no:
    if x == 0: continue

    let rnumb = $rand(lo..hi)
    stdout.write rnumb & '\n'

method execute*(util: Rand): int =
  if util.arguments.isSwitchEnabled("help", "h"):
    util.showHelp()

  if util.arguments.isSwitchEnabled("credits", "C"):
    util.showCredits()
  
  let targets = util.arguments.getTargets()

  if targets.len < 1:
    util.error("no mode specified! Run --help for more information")

  if not util.arguments.isSwitchEnabled("dont-randomize", "d"):
    randomize()
  
  let mode = case targets[0]
  of "int":
    RandInt
  of "choice":
    RandChoice
  else:
    RandInvalid

  case mode
  of RandInvalid:
    util.error("invalid mode: " & targets[0])
  of RandChoice:
    util.choices()
  of RandInt:
    util.randint()
  
  0

when isMainModule:
  let rand = Rand(
    name: "rand",
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

  rand.run()
