#

import std/[strutils, json, posix, os],
       jsony,
       ../norecore/[
          argparse,
          coreutil
        ]

type
  Operation* = enum
    oGet
    oSet
    oPrettify

  Json* = ref object of Coreutil

method showHelp*(util: Json) =
  echo """
Usage: json [data] [options]
Work with JSON. Either supply JSON data, or point to a JSON file.
If no flag is provided, prettify the JSON and output it to stdout.

  --help -h             display this message
  --get, -g             get an attribute from the supplied data, granted it exists.
  --set, -s             set an attribute from the supplied data, and output the changed output.
  --pretty, -p          all output must be prettified.

Examples:
  json "{\"my_key\": \"hello world\"}" --get "my_key"
  json "{\"my_key\": \"hello world\"}" --set "my_key" "goodbye world"

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

proc handle*(util: Json, target: string, operation: Operation) =
  var parsed: JsonNode

  if not fileExists(target):
    parsed = target.fromJson()
  else:
    parsed = readFile(target).fromJson()
  
  if operation == oPrettify:
    echo parsed.pretty()

  let targets = util.arguments.getTargets()
  if operation == oGet:
    if targets.len < 2:
      util.error("no key specified")

    for x in 1..targets.len-1:
      let t = targets[x]
      let data = parsed{t}

      echo data.getStr()

  if operation == oSet:
    if (targets.len-1) mod 2 != 0:
      util.error("all key-value pairs must be even in number in order to be evaluated")

    var pos = 1
    
    while pos < targets.len:
      let 
        key = targets[pos]
        value = targets[pos + 1]
      
      parsed{key} = newJString(value)
      
      pos += 2

    if util.arguments.isSwitchEnabled("pretty", "p"):
      echo parsed.pretty()
    else:
      echo $parsed

method execute*(util: Json): int =
  let targets = util.arguments.getTargets()

  if targets.len < 1:
    util.error("expected JSON data or JSON file, got nothing\nrun --help for more information")

  let target = targets[0] 
  var operation: Operation

  if util.arguments.isSwitchEnabled("get", "g"):
    operation = oGet
  elif util.arguments.isSwitchEnabled("set", "s"):
    operation = oSet
  else:
    operation = oPrettify
  
  util.handle(target, operation)
  0

when isMainModule:
  let util = Json(
    name: "json",
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

  util.run()
