import std/[os, times, tables, sysrand, sequtils, strutils, posix, json],
       ../norecore/[
          argparse,
          coreutil,
          bytes
        ],
        jsony,
        nimAesCrypt

const 
  FORBIDDEN = [
    "/",
    "/nix/store/",
    "/home/",
    "/*",
    "/usr/bin/",
    "/usr/"
  ]
  TRASH_DIR {.strdefine.} = ".trash"
  TRASH_REGISTER {.strdefine.} = ".trash-internal" / "register.json"

type
  Trash* = ref object of Coreutil

method showHelp*(trash: Trash) =
  echo """
Usage: trash [options] [targets]
Store a file in ~/.trash/ until you truly want it deleted.

  --help, -h                              display this message
  --just-shred, -js                       just shred the file, don't delete it
  --dump-registry, -dr                    dump everything in the trash registry
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
    
    try:
      writeFile(
        target, rand
      )
    except IOError as exc:
      echo "trash: critical: could not write random bytes to " & target & ": " & exc.msg
      echo "trash: critical: this file can be easily recovered using simple tools. Good luck."
    except OSError as exc:
      echo "trash: critical: cannot write random bytes to " & target & ": " & exc.msg
      echo "trash: critical: this file can be easily recovered using simple tools. Good luck."

    discard dataLen
    discard rand

proc handle*(
  trash: Trash,
  target: string,
  recursive, safetyChecks, immediate, dontShred, dontAsk, justShred: bool,
  encryptionKey: string, shredPasses: uint,
  verbose: bool
) =
  var 
    fExist = fileExists target
    dExist = dirExists target

  if not fExist and not dExist:
    trash.error(target & ": No such file or directory")
  
  if dExist and not recursive:
    trash.error(target & ": Is a directory")

  if access(target, R_OK) != 0 or access(target, W_OK) != 0:
    trash.error(target & ": Permission denied")
  
  # We have to read the data in advance or everything turns to scheisse.
  let data = readFile(getHomeDir() / TRASH_REGISTER)
  let file = open(getHomeDir() / TRASH_REGISTER, fmWrite)
  defer: file.close()

  echo data
  
  var rData = data
    .fromJson(TableRef[string, Table[string, string]])

  if not immediate:
    # Store stuff in ~/.trash
    if fExist:
      let path = getHomeDir() / TRASH_DIR / target
      var data = readFile target

      if fileExists(path) or dirExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
      
      let splitted = path.splitFile()
      
      # Weweee
      if not dirExists(splitted.dir):
        var prev: string = "/"
        for d in splitted.dir.split('/'):
          if not dirExists(prev / d):
            createDir(prev / d)
          
          prev = prev / d

        echo prev

      writeFile(path, data)

      if encryptionKey.len > 0:
        if verbose:
          echo "trash: encrypting " & target & " using AES256 with buffer size set to 512"
        encryptFile(path, path, encryptionKey, 512)

      removeFile(target)

      rData[target] = {
        "kind": "f",
        "path": path,
        "deleted_on": $now(),
        "encrypted": $(encryptionKey.len > 0),
        "belongs_to": absolutePath target
      }.toTable
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
        handle(trash, child, recursive, safetyChecks, immediate, dontShred, dontAsk, justShred, encryptionKey, shredPasses, verbose)
      
      rData[target] = {
        "kind": "d",
        "path": path,
        "deleted_on": $now(),
        "encrypted": "false", # How do ya encrypt a directory? kekw,
        "belongs_to": absolutePath target
      }.toTable
  else:
    # Delete stuff immediately.
    if fExist:
      if not dontShred:
        shred(target, shredPasses)
      
      if not justShred:
        if verbose:
          echo "trash: removing file: " & target
        removeFile(target)
    elif dExist:
      if target in FORBIDDEN and safetyChecks:
        trash.error(target & ": Forbidden target, if you really want to delete it, use --i-am-really-stupid")

      let path = getHomeDir() / TRASH_DIR / target

      if dirExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."
        if not justShred:
          if verbose:
            echo "trash: removing directory: " & target

          removeDir(path)
      elif fileExists(path):
        echo "trash: " & target & " already exists in trash, overwriting."

        if not justShred:
          if verbose:
            echo "trash: removing file: " & target

          removeFile(path)
      
      for _, child in walkDir(target):
        handle(trash, child, recursive, safetyChecks, immediate, dontShred, dontAsk, justShred, encryptionKey, shredPasses, verbose)
      
      removeDir(target)
  
  file.write(rData.toJson())

proc recover*(trash: Trash, target: string, verbose: bool, encryptionKey: string = "", literal: bool = false) =
  let data = readFile(getHomeDir() / TRASH_REGISTER)
  let registry = open(getHomeDir() / TRASH_REGISTER, fmWrite)
  var rData = data
    .fromJson(TableRef[string, Table[string, string]])

  if target notin rData:
    trash.error(target & ": No such file or directory in trash records")

  var path: string
  
  if not literal:
    path = getHomeDir() / TRASH_DIR / target
  else:
    path = target
  
  var
    fExists = fileExists path
    dExists = dirExists path

  if not fExists and not dExists:
    trash.error(target & ": No such file or directory in trash directory")

  if fExists:
    if encryptionKey.len < 1:
      moveFile(path, rData[target]["belongs_to"])
    else:
      decryptFile(path, rData[target]["belongs_to"], encryptionKey, 512)
    
    if rData[target]["encrypted"].parseBool():
     echo "trash: It seems that this file is encrypted and you forgot to provide an encryption key. If you want, you can provide one right now: "
     decryptFile(path, target, stdin.readLine(), 512)
  elif dExists:
    if dirExists target:
      removeDir(target)

    copyDir(path, target)

    for _, k in walkDir(path):
      if verbose:
        echo "trash: recovering child of \"" & target & "\": " & path / k.splitPath().tail
      trash.recover(path / k.splitPath().tail, verbose, encryptionKey, true)

    removeDir(path)
  
  rData.del(target)
  echo "trash: recovered " & target
  writeFile(getHomeDir() / TRASH_REGISTER, rData.toJson())

proc dumpRegister*(trash: Trash) =
  let file = open(getHomeDir() / TRASH_REGISTER, fmRead)
  defer: file.close()

  let data = file
    .readAll()
    .fromJson()

  echo data.pretty()

method execute*(trash: Trash): int =
  let exists = fileExists(getHomeDir() / TRASH_REGISTER)
  discard existsOrCreateDir(getHomeDir() / TRASH_REGISTER.splitFile().dir)

  if not exists:
    writeFile(getHomeDir() / TRASH_REGISTER, """
{
  "": {
    "kind": "NONE",
    "path": "/",
    "encrypted": "true",
    "deleted_on": "1984-6-05T12:40:29+5:30",
    "belongs_to": ""
  }
}
    """)
  else:
    if readFile(getHomeDir() / TRASH_REGISTER).isEmptyOrWhitespace():
      writeFile(getHomeDir() / TRASH_REGISTER, """
{
  "": {
    "kind": "NONE",
    "path": "/",
    "encrypted": "true",
    "deleted_on": "1984-6-05T12:40:29+5:30",
    "belongs_to": ""
  }
}
      """)
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
    justShred = trash.arguments.isSwitchEnabled("just-shred", "js")
    verbose = trash.arguments.isSwitchEnabled("verbose", "v")
    dumpRegister = trash.arguments.isSwitchEnabled("dump-register", "dr")

  var
    encryptionKey: string
    shredPasses: uint

  if dumpRegister:
    trash.dumpRegister()

  if e1.len > 0:
    var data = e1
    encryptionKey = data
  elif e2.len > 0:
    var data = e2
    encryptionKey = data

  if shredPassesA.len > 0:
    for c in shredPassesA:
      if c notin {'0'..'9'}:
        trash.error("shred-passes must be an unsigned integer!")

    shredPasses = parseUint(shredPassesA)
  else:
    if verbose:
      echo "trash: shred-passes not provided, defaulting to 8"
    shredPasses = 8'u
  
  discard existsOrCreateDir(getHomeDir() / TRASH_DIR)

  if doEmpty:
    if not noAudit:
      if verbose:
        echo "trash: will show audit"

      echo "trash: Press ENTER to show your audit."
      discard stdin.readLine()
      discard execShellCmd("ls --recursive " & getHomeDir() / TRASH_DIR & " | less")

      echo "trash: Do you really want to continue? [y/N]"
      let answer = stdin.readLine().toLowerAscii()

      if answer != "y":
        echo "trash: aborted"
        quit(0)
    else:
      if verbose:
        echo "trash: will not show audit."

    for _, f in walkDir(getHomeDir() / TRASH_DIR):
      if verbose:
        echo "trash: shredding " & f
      handle(trash, f, true, true, true, dontShred, dontAsk, justShred, "", shredPasses, verbose)
    
    echo "trash: Shredded everything in ~/.trash, the contents can no longer be recovered by trash."
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
        justShred,
        encryptionKey,
        shredPasses,
        verbose
      )
  else:
    for _, target in targets:
      trash.recover(target, verbose, encryptionKey)

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
