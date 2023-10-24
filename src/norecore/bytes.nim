# Taken from https://github.com/nim-lang/Nim/issues/14810
# thanks, ringabout :D

func toByteSeq*(str: string): seq[byte] {.inline.} =
  ## Converts a string to the corresponding byte sequence.
  @(str.toOpenArrayByte(0, str.high))

func toString*(bytes: openArray[byte]): string {.inline.} =
  ## Converts a byte sequence to the corresponding string.
  let length = bytes.len
  if length > 0:
    result = newString(length)
    copyMem(result.cstring, bytes[0].unsafeAddr, length)
