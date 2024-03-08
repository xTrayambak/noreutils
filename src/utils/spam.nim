#

import std/os,
       ../norecore/[
          argparse,
          coreutil,
          output
        ]

type
  SpamGenericMode* = enum
    None
    Confirmation # y
    Denial # n

  Spam* = ref object of Coreutil

method showHelp*(spam: Spam) =
  echo """
Usage: spam [string] [options]
Spam `string` to stdout.

Options:
  --confirm, -c, --yes, -y           Spam "yes"
  --deny, -d, --no, -n               Spam "no"

Usage:
  spam y | sudo dnf install curl # this will auto-confirm the "are you sure you want to install this?" prompt

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

method execute*(spam: Spam): int =
  if spam.arguments.isSwitchEnabled("help", "h"):
    spam.showHelp()

  var mode = None

  if spam.arguments.isSwitchEnabled("confirm", "c"):
    mode = Confirmation

  if spam.arguments.isSwitchEnabled("yes", "y"):
    mode = Confirmation
  
  if spam.arguments.isSwitchEnabled("deny", "d"):
    mode = Denial

  if spam.arguments.isSwitchEnabled("no", "n"):
    mode = Denial

  let targets = spam.arguments.getTargets()

  if targets.len < 1 and mode == None:
    spam.error("No target or mode specified! Run --help for more information.")

  let target = case mode
  of Confirmation: "yes"
  of Denial: "no"
  else: targets[0]

  while fullWrite(target):
    continue

  0

when isMainModule:
  let spam = Spam(
    name: "spam",
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

  spam.run()
