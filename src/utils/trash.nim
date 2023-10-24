import std/[os, sysrand, sugar, sequtils, strutils, posix],
       ../norecore/[
          argparse,
          coreutil,
          bytes
        ],
        nimAesCrypt

const 
  FORBIDDEN = [
    "/",
    "/home/"
  ]
  TRASH_DIR {.strdefine.} = ".trash"

type
  Trash* = ref object of Coreutil

method showHelp*(trash: Trash) =
  echo """
Usage: trash [options] [targets]
Store a file in ~/.trash/ until you truly want it deleted.

  --help, -h                              display this message
  --recover, -R                           recover a file from ~/.trash
  --recursive, -r                         recursively delete all files in a directory
  --immediate, -i                         don't store in ~/.trash, just delete the file immediately
  --i-am-really-stupid, -iars             disable checks that prevent deleting system files
  --empty, -E                             truly destroy all files forever in trash
  --encrypt, -e                           encrypt the files being stored in ~/.trash using AES256
  --no-audit, -nA                         don't display an audit of files about to be deleted
  --dont-shred, -nS                       don't shred data, just tell the filesystem to remove it, the data will be recoverable very easily
  --shred-passes, -s                      the amount of times a file will be filled with random data before being deleted, more passes means it will be harder to recover the file (default=8)

Examples:
  trash --immediate the-cure-to-cancer.pdf                Use this when the CIA finds you
  trash --encrypt epicgamerkey my-darkest-secrets.txt     Nobody will now know that you have a crippling Vtuber addiction

Noreutils doesn't have docs. Git gud. :)
"""

proc shred*(target: string, shredPasses: uint) =
  let dataLen: int = readFile(target).len
  for n in 0..shredPasses:
    var rand = newStringOfCap(dataLen + 8)

    rand &= urandom(dataLen + 2).toString()

    writeFile(
      target, rand
    )
    discard dataLen
    discard rand

proc handle*(
  trash: Trash,
  target: string,
  recursive, safetyChecks, immediate, dontShred, dontAsk: bool,
  encryptionKey: string, shredPasses: uint
) =
  var 
    fExist = fileExists target
    dExist = dirExists target

  if not fExist and not dExist:
    trash.error(target & ": No such file or directory")
  
  if dExist and not recursive:
    trash.error(target & ": Is a directory")

  if access(target, R_OK) != 0:
    trash.error(target & ": Permission denied")

  if not immediate:
    if fExist:
      let path = getHomeDir() / TRASH_DIR / target
      var data = readFile target

      if fileExists(path) or dirExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
      
      writeFile(path, data)

      if encryptionKey.len > 0:
        encryptFile(path, path, encryptionKey, 512)

      removeFile(target)
    elif dExist:
      if target in FORBIDDEN and safetyChecks:
        trash.error(target & ": Forbidden target, if you really want to delete it, use --i-am-really-stupid")

      let path = getHomeDir() / TRASH_DIR / target

      if dirExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
        removeDir(path)
      elif fileExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
        removeFile(path)
      
      moveDir(target, path)

      for _, child in walkDir(target):
        handle(trash, child, recursive, safetyChecks, immediate, dontShred, dontAsk, encryptionKey, shredPasses)
  else:
    if fExist:
      echo "mv: Confirm that you want to delete: " & target & " [y/N]"
      let answer = stdin.readLine().toLowerAscii()

      if answer != "y":
        echo "mv: Won't delete " & target
        return
    
      if not dontShred:
        shred(target, shredPasses)

      removeFile(target)
    elif dExist:
      if target in FORBIDDEN and safetyChecks:
        trash.error(target & ": Forbidden target, if you really want to delete it, use --i-am-really-stupid")

      let path = getHomeDir() / TRASH_DIR / target

      if dirExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
        removeDir(path)
      elif fileExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
        removeFile(path)
      
      for _, child in walkDir(target):
        handle(trash, child, recursive, safetyChecks, immediate, dontShred, dontAsk, encryptionKey, shredPasses)

      removeDir(target)

proc recover*(trash: Trash, target: string) =
  let path = getHomeDir() / TRASH_DIR / target
  
  var
    fExists = fileExists path
    dExists = dirExists path

  if not fExists and not dExists:
    trash.error(target & ": No such file or directory")

  if fExists:
    moveFile(path, target)
  elif dExists:
    if dirExists target:
      removeDir(target)

    copyDir(path, target)

    for _, k in walkDir(path):
      trash.recover(path.splitPath().tail / k.splitPath().tail)

    removeDir(path)

method execute*(trash: Trash): int =
  if trash.arguments.isSwitchEnabled("help", "h"):
    trash.showHelp()

  if trash.arguments.isSwitchEnabled("credits", "C"):
    trash.showCredits()
  
  let 
    targets = trash.arguments.getTargets()
    recursive = trash.arguments.isSwitchEnabled("recursive", "r")
    recover = trash.arguments.isSwitchEnabled("recover", "R")
    safetyChecks = not trash.arguments.isSwitchEnabled("i-am-really-stupid", "iars")
    doEmpty = trash.arguments.isSwitchEnabled("empty", "E")
    e1 = trash.arguments.getFlag("encrypt")
    immediate = trash.arguments.isSwitchEnabled("immediate", "i")
    e2 = trash.arguments.getFlag("e")
    noAudit = trash.arguments.isSwitchEnabled("no-audit", "nA")
    dontShred = trash.arguments.isSwitchEnabled("dont-shred", "nS")
    shredPassesA = trash.arguments.getFlag("shred-passes")
    dontAsk = trash.arguments.isSwitchEnabled("no-confirm", "nC")

  var encryptionKey: string
  var shredPasses: uint

  if e1.len > 0:
    encryptionKey = e1
  elif e2.len > 0:
    encryptionKey = e2

  if shredPassesA.len > 0:
    shredPasses = parseUInt(shredPassesA)
  else:
    shredPasses = 8'u
  
  discard existsOrCreateDir(getHomeDir() / TRASH_DIR)

  if doEmpty:
    if not noAudit:
      echo "trash: Press ENTER to show your audit."
      discard stdin.readLine()
      discard execShellCmd("ls --recursive " & getHomeDir() / TRASH_DIR & " | less")

      echo "trash: Do you really want to continue? [y/N]"
      let answer = stdin.readLine().toLowerAscii()

      if answer != "y":
        echo "trash: Aborted."
        quit(0)

    for _, f in walkDir(getHomeDir() / TRASH_DIR):
      echo f
      handle(trash, f, true, true, true, dontShred, dontAsk, "", shredPasses)
    
    return 0
  
  if not recover:
    for _, target in targets:
      trash.handle(
        target,
        recursive,
        safetyChecks,
        immediate,
        dontShred,
        dontAsk,
        encryptionKey,
        shredPasses
      )
  else:
    for _, target in targets:
      trash.recover(target)
  
  # Deallocate everything sensitive to prevent data leakage
  discard shredPasses
  discard encryptionKey
  discard e1
  discard e2
  0

when isMainModule:
  let trash = Trash(
    name: "trash",
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

  trash.run()
