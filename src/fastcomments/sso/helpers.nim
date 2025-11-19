import std/strutils
import nimcrypto/[hmac, sha2]

type
  CreateHashError* = object of CatchableError

proc getBytesAsHex*(data: openArray[byte]): string =
  ## Convert bytes to hexadecimal string
  result = ""
  for b in data:
    result.add(toHex(int(b), 2).toLowerAscii())

proc createVerificationHash*(apiKey: string, timestamp: int64, userDataJsonBase64: string): string =
  ## Create a verification hash using HMAC-SHA256
  try:
    let message = $timestamp & userDataJsonBase64
    var ctx: HMAC[sha256]
    ctx.init(apiKey)
    ctx.update(message)
    let hash = ctx.finish()
    result = getBytesAsHex(hash.data)
  except Exception as e:
    raise newException(CreateHashError, "Failed to create verification hash: " & e.msg)
