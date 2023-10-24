import std/[strutils, os, sets, posix],
       ../norecore/[
          argparse,
          coreutil
        ]

type
  MvKind* = enum
    Dir
    File

  Mv* = ref object of Coreutil

proc handle*(mv: Mv, target, dest: string, verbose: bool = false) =
  for x in [target, dest]:
    if not fileExists(x) and not dirExists(x):
      echo "mv: cannot stat '" & x & "': No such file or directory"
      quit 1

    if access(x, W_OK) != 0:
      echo "mv: cannot mutate '" & x & "': Permission denied"
      quit 1

  var tKind, dKind: MvKind
    
  if fileExists(target):
    if not dirExists(target):
      tKind = File
    else:
      if target.startsWith("./"):
        tKind = File
      else:
        tKind = Dir
  else:
    tKind = Dir

  if fileExists(dest):
    if not dirExists(dest):
      dKind = File
    else:
      if dest.startsWith("./"):
        dKind = File
      else:
        dKind = Dir
  else:
    dKind = Dir

  if tKind == File and dKind == File:
    if verbose:
      echo "mv: both target and dest are files, moving target to " & dest

    moveFile(target, dest)
  elif tKind == File and dKind == Dir:
    if verbose:
      echo "mv: target is a file and dest is a directory, moving target to " & dest / target

    moveFile(target, dest / target)
  elif tKind == Dir and dKind == File:
    mv.error(target & ": ' is a directory and '" & dest & "' is a file, cannot overwrite them.")
  elif tKind == Dir and dKind == Dir:
    # Merge them
    if verbose:
      echo "mv: both target and dest are directories, merging " & target & " into " & dest

    for tFile in walkDirRec(target, {pcFile, pcDir}):
      if verbose:
        echo "mv: moving " & tFile & " to " & dest / tFile

      createDir(dest / tFile.split('/')[0])

      if tFile.fileExists():
        moveFile(tFile, dest / tFile)
      elif tFile.dirExists():
        moveDir(tFile, dest / tFile)
  else:
    echo "mv: unimplemented condition (this should never happen)"
    echo "mv: tKind = " & $tKind & "; mKind = " & $dKind

method execute*(mv: Mv): int =
  if mv.arguments.isSwitchEnabled("help", "h"):
    mv.showHelp()
    quit 0

  if mv.arguments.isSwitchEnabled("credits", "c"):
    mv.showCredits()
    quit 0

  let targets = mv.arguments.getTargets()

  if targets.len < 1:
    echo "mv: missing file operand"
    echo "Try mv --help for more information."
    quit 1

  if targets.len mod 2 != 0:
    echo "mv: files must be in pairs or the operation cannot continue."
    echo '"' & targets[targets.len-1] & "\" does not have a pair."
    quit 1

  var pos = -2

  let verbose = mv.arguments.isSwitchEnabled("verbose", "V")

  while pos < targets.len - 2:
    pos += 2
    let 
      t1 = targets[pos]
      t2 = targets[pos + 1]
    
    mv.handle(t1, t2, verbose)
  
  0

when isMainModule:
  let mv = Mv(
    name: "mv",
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

  mv.run()
