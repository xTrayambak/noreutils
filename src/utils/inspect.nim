#

import std/[os, options, strutils, net],
       ../norecore/[
          argparse,
          coreutil
        ]

type
  Inspect* = ref object of Coreutil

method showHelp*(inspect: Inspect) =
  echo """
Usage: inspect address:port [options]
Inspect a TCP socket, poke at it, do whatever you want to.

  --help, -h            display this message
  --is-open, -i         is the socket accepting connections? If not, then the program outputs 'false' to stdout and exists.
  --send <data>     send some data to the socket, and close the connection
  --recv <num>      Receive <num> amount of bytes and output it to stdout.

Examples:
  inspect localhost:8080 --is-open --send "Hello noreutils" --recv 128

Noreutils doesn't have docs. Git gud. :)
"""
  quit 0

proc splitIpPair*(s: string): tuple[address: Option[string], port: Option[int], error: Option[string]] =
  var 
    address: string
    rport: string
    hitColon: bool

  for c in s:
    case c
    of ':':
      hitColon = true
      continue
    of {'a'..'z'}, {'A'..'Z'}:
      if not hitColon:
        address &= c
      else:
        return (address: none(string), port: none(int), error: some("Got alphabetical character in port number"))
    of {'0'..'9'}:
      if not hitColon:
        address &= c
      else:
        rport &= c
    else:
      return (address: none(string), port: none(int), error: some("Invalid character: " & c))
  
  when not defined(danger):
    # -1: not initialized
    # 0: numerical only
    # 1: alphabetical only
    var alphabetical = -1
    for c in address:
      case c
      of {'a'..'z'}, {'A'..'Z'}:
        case alphabetical
        of -1:
          alphabetical = 1
        of 0:
          return (address: none(string), port: none(int), error: some("Got alphabetical character in numeric address: " & c))
        else: discard
      of {'0'..'9'}:
        case alphabetical
        of -1:
          alphabetical = 0
        of 1:
          return (address: none(string), port: none(int), error: some("Got numerical character in alphabetical address: " & c))
        else: discard
      else: discard

  (
    address: some address, 
    port: some parseInt rport,
    error: none(string)
  )

method execute*(inspect: Inspect): int =
  if inspect.arguments.isSwitchEnabled("help", "h"):
    inspect.showHelp()

  if inspect.arguments.isSwitchEnabled("credits", "C"):
    inspect.showCredits()

  let targets = inspect.arguments.getTargets()

  if targets.len > 1:
    inspect.error("got multiple address-port combinations, expected one. See --help for more information.")

  if targets.len < 1:
    inspect.error("got no address-port combinations, expected one. See --help for more information.")

  let ip = splitIpPair(targets[0])

  var 
    sIsOpen = inspect.arguments.isSwitchEnabled("is-open", "i")
    sSend = inspect.arguments.getFlag("send")
    sRecv = inspect.arguments.getFlag("recv")
    iRecv: int
  
  if sRecv.len > 0:
    try:
      iRecv = sRecv.parseInt()
    except ValueError:
      inspect.error("invalid number of bytes to receive provided")

  let noIntentToSend = (sSend.len < 1 and sRecv.len < 1) and sIsOpen

  if ip.address.isNone:
    inspect.error(ip.error.unsafeGet())

  let sock = newSocket(AF_INET, SOCK_STREAM)

  try:
    sock.connect(ip.address.unsafeGet(), Port(ip.port.unsafeGet()))
  except OSError as exc:
    if noIntentToSend:
      echo "false"
      quit(0)
    else:
      inspect.error(exc.msg)
  finally:
    echo "true"
    if noIntentToSend:
      quit(0)
  
  if sSend.len > 0:
    sock.send(sSend)

  if iRecv > 0:
    echo sock.recv(iRecv)

when isMainModule:
  let inspect = Inspect(
    name: "inspect",
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

  inspect.run()
