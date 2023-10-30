# do-not-compile

import std/[strutils, posix, os],
       ../norecore/[
          argparse,
          coreutil
        ]

type
  CachedMode* = enum
    cDefault
    cAlways
    cNever

  StatUtil* = ref object of Coreutil

const 
  cachedArgs = ["default", "never", "always"]
  cachedModes = [cDefault, cNever, cAlways]

method showHelp*(st: StatUtil) =
  echo """
Usage: stat [options] [targets]
Display file status.

  --help -h             display this message

Examples:
  stat myfile.txt
  stat ./myexecutable

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

proc handle*(st: StatUtil, target: string): string =
  var inf: Stat
  
  case stat(target, inf):
    of EACCES:
      st.error(target & ": search permission is denied (EACCES)")
    of EBADF:
      st.error(target & ": pathname is relative but dirfd is neither AT_FDCWD nor a valid file descriptor (EBADF)")
    of EINVAL:
      st.error(target & ": EINVAL")
    of ENOMEM:
      st.error(target & ": out of memory")
    of 0: discard
    else: st.error(target & ": unhandled non-zero error on stat() call")

  var str: string

  str &= "  File: " & target
  str &= "\n  Size: " & $inf.st_size
  str &= "\tBlocks: " & $inf.st_blksize
  str &= "\tIO Block: " & $inf.st_blocks

  str &= "  Device: " & $inf.st_dev
  str &= "\tInode: " & $inf.st_ino
  str &= "\tLinks: " & $inf.st_nlink
  str &= "\nAccess: " & $inf.st_mode
  str &= "\tUid: " & $inf.st_uid
  str &= "\tGid: " & $inf.st_gid
  str &= "\nAccess: " & $inf.st_atim
  str &= "\nModify: " & $inf.st_mtim
  str &= "\nChange: " & $inf.st_ctim

  str

method execute*(st: StatUtil): int =
  if st.arguments.isSwitchEnabled("help", "h"):
    st.showHelp()

  if st.arguments.isSwitchEnabled("credits", "c"):
    st.showCredits()

  let targets = st.arguments.getTargets()

  if targets.len < 1:
    st.error("missing operand; try --help for more information")

  for target in targets:
    echo st.handle(target)

  0

when isMainModule:
  let st = StatUtil(
    name: "stat",
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

  st.run()
