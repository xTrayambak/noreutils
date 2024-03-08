# -d:ssl

import std/[strutils, httpclient, os, posix],
       ../norecore/[
          argparse,
          coreutil,
          colors
        ] 

const DONT_CONSIDER_HEADERS = [
  "only-body"
]
const NimblePkgVersion {.strdefine.} = "0.1.0"

type
  Net* = ref object of Coreutil
    updateTimeProgressBar*: int

method showHelp*(net: Net) =
  echo """
net [options] [target]
Send a HTTP request to a particular web server for a response.
Basically, cURL from AliExpress.

  --<header>:<value>    Set a request header.
  --only-body, -ob      Only print the body, nothing else.
  --no-pretty, -np      Don't print colored output, don't make seperator bars. Just print the headers and body seperated by a single newline. Useful for parsing the output.
  --only-headers, -oh   Only print the response headers.
  --output:<file>       Output the response body to a file.
"""

proc handle*(
  net: Net, 
  target: string,
  noPretty, onlyBody, onlyHeaders: bool,
  headers: HttpHeaders,
  httpClient: HttpClient,
  output: string = ""
) =
  if target.startsWith("https"):
    when not defined(ssl):
      net.error(target & ": cannot connect to URL, noreutils was compiled without SSL support!")

  let response = httpClient.get(target)
    
  if output.len < 1:
    if not noPretty:
      echo repeat('=', 32)
      echo green & "URL" & areset & ": " & yellow & target & areset
      echo green & "HTTP protocol" & areset & ": " & yellow & response.version & areset
      echo green & "Request Headers" & areset & ':' & areset
      
      for header, value in headers:
        echo '\t' & blue & header & areset & ": " & yellow & value & areset
      
      echo green & "Response Headers" & areset & ':' & areset
      for header, value in response.headers:
        echo '\t' & yellow & header & areset & ": " & blue & value & areset
      
      echo green & "\nResponse Body" & areset & ':'
      echo response.body()
      echo repeat('=', 32)
    else:
      if onlyBody:
        echo response.body()
      elif onlyHeaders:
        for header, value in headers:
          echo header & ": " & value
      
        echo "\n\n"

        for header, value in response.headers:
          echo header & ": " & value
      else:
        echo "URL" & ':' & target
        echo "HTTP protocol" & ": " & response.version
        echo "Request Headers" & ':'

        for header, value in headers:
          echo '\t' & header & value
      
        echo "Response Headers:"
        for header, value in response.headers:
          echo '\t' & header & ": " & value

        echo "Response Body:"
        echo response.body()
  else:
    if dirExists(output) and not fileExists(output):
      net.error(output & ": is a directory")

    if fileExists(output) and access(output, W_OK) != 0: 
      net.error(output & ": cannot mutate; permission denied")

    writeFile(output, response.body())

method execute*(net: Net): int =
  if net.arguments.isSwitchEnabled("help", "h"):
    net.showHelp()

  if net.arguments.isSwitchEnabled("credits", "c"):
    net.showCredits()

  let
    onlyBody = net.arguments.isSwitchEnabled("only-body", "ob")
    noPretty = net.arguments.isSwitchEnabled("no-pretty", "np")
    onlyHeaders = net.arguments.isSwitchEnabled("only-headers", "oh")
    output = net.arguments.getFlag("output")
    progressBar = net.arguments.isSwitchEnabled("progress-bar", "pb")

  let flags = net.arguments.getFlags()
  let httpClient = newHttpClient()

  var headers = newHttpHeaders()
  
  for flag in flags:
    if flag.key notin DONT_CONSIDER_HEADERS:
      if flag.value.len > 0:
        headers[flag.key] = flag.value
      else:
        net.error(flag.key & ": expected value for header, got nothing")

  for target in net.arguments.getTargets():
    net.handle(
      target, 
      noPretty, onlyBody, onlyHeaders, 
      headers, httpClient, output
    )
    
when isMainModule:
  let net = Net(
    name: "net",
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

  net.run()
