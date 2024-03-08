proc fullWrite*(
  msg: string,
  file: File = stdout
): bool {.inline.} =
  try:
    file.write(msg & '\n')
    return true
  except CatchableError:
    return false
