import std/[strutils, os, osproc], norecore/argparse

discard existsOrCreateDir("bin/")

proc compileAll =
  when not defined(release):
    for file in walkFiles("src/utils/*.nim"):
      let contents = readFile(file)
      let lines = contents.splitLines()
      if lines[0] == "# do-not-compile": 
        continue

      var cmd = lines[0]
      cmd.removePrefix('#')

      echo "=> " & file
      let res = execCmdEx("nim c " & cmd & " -o:bin/ " & file)
      if res.exitCode != 0:
        echo "=> BUILD FAILED."

      echo res.output
  else:
    for file in walkFiles("src/utils/*.nim"):
      let contents = readFile(file)
      let lines = contents.splitLines()
      if lines[0] == "# do-not-compile": 
        continue

      var cmd = lines[0]
      cmd.removePrefix('#')

      echo "=> " & file & " (" & cmd & ")"
      let res = execCmdEx("nim c -d:release " & cmd & " -o:bin/ " & file)
      if res.exitCode != 0:
        echo "=> BUILD FAILED."

      echo res.output

proc compileOne(util: string) =
  if not fileExists("src/utils/" & util & ".nim"):
    echo "=> COREUTIL NOT FOUND."
    quit 1
  
  echo "=> src/utils/" & util & ".nim"
  when defined(release):
    let res = execCmdEx("nim c -d:release -o:bin/ " & "src/utils/" & util)

    if res.exitCode != 0:
      echo "=> BUILD FAILED."

    echo res.output
  else:
    let res = execCmdEx("nim c -o:bin/ " & "src/utils/" & util)

    if res.exitCode != 0:
      echo "=> BUILD FAILED."

    echo res.output

when isMainModule:
  var args = parseArguments()
  let targets = args.getTargets()

  if targets.len < 1:
    compileAll()
  else:
    for target in targets:
      compileOne(target)
