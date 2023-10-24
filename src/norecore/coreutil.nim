import argparse

type 
  Author* = ref object of RootObj
    firstName*: string
    middleName*: string
    lastName*: string
    middleNameInQuotations*: bool

  Coreutil* = ref object of RootObj
    name*: string
    authors*: seq[Author]
    arguments*: seq[Argument]

method showHelp*(coreutil: Coreutil) {.base.} =
  echo "no help 4 u"

method error*(coreutil: Coreutil, msg: string, exitCode: int = 1) {.noReturn base inline.} =
  echo coreutil.name & ": " & msg
  quit exitCode

proc showCredits*(coreutil: Coreutil) =
  var creditStr = "The following people have contributed to this core utility.\n"

  for author in coreutil.authors:
    creditStr &= author.firstName & " "

    if author.middleNameInQuotations:
      creditStr &= '"' & author.middleName & "\" "
    else:
      creditStr &= author.middleName & ' '

    creditStr &= author.lastName

  echo creditStr

method execute*(coreutil: Coreutil): int {.base.} =
  0

proc run*(coreutil: Coreutil) =
  quit coreutil.execute()
