import std/[os, strutils, base64],
       ../norecore/[
argparse,
          coreutil
        ]

type
  Base64Mode* = enum
    Encode
    Decode

  Base64* = ref object of Coreutil

method showHelp*(b64: Base64) =
  echo """
Usage: base64 [options] [targets]
Encode a file or a string into base64 encoding or
decode a file or a string from base64 encoding.

  --help, -h            display this message
  --decode, -d          decode a file/string
  --encode, -e          encode a file/string
  --ignore-garbage, -i  ignore non-alphabetical characters

Examples:
  base64 -e Meow        Encode "meow" into base64 and output the result
  base64 -d "TkVFRVJE"  Decode this seemingly innocuous message

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

proc handle*(b64: Base64, target: string, mode: Base64Mode) =
  if mode == Encode:
    var content = deepCopy target

    if fileExists(target):
      content = readFile(target)

    content = encode(content, safe = b64.arguments.isSwitchEnabled("url-safe", "Us"))
    
    if b64.arguments.isSwitchEnabled("ignore-garbage", "i"):
      let splitted = content.split('=')
      stdout.write splitted[0] & '\n'
    else:
      stdout.write content & '\n'
  else:
    var
      content = deepCopy target
      final: string

    if fileExists(target):
      content = readFile(target)

    if b64.arguments.isSwitchEnabled("ignore-garbage", "i"):
      for c in decode content:
        if c.isAlphaAscii():
          final &= c
    else:
      final = decode content

    stdout.write final & '\n'

method execute*(b64: Base64): int =
  if b64.arguments.isSwitchEnabled("help", "h"):
    b64.showHelp()

  if b64.arguments.isSwitchEnabled("credits", "C"):
    b64.showCredits()
  
  let targets = b64.arguments.getTargets()
  var mode: Base64Mode

  if b64.arguments.isSwitchEnabled("encode", "e"):
    mode = Encode
  elif b64.arguments.isSwitchEnabled("decode", "d"):
    mode = Decode
  else:
    echo "No mode specified. Run --help for more information."
    quit 1

  for _, target in targets:
    b64.handle(target, mode)

  0

when isMainModule:
  let b64 = Base64(
    name: "base64",
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

  b64.run()
