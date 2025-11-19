import std/json

type
  SecureSSOPayload* = object
    userDataJsonBase64*: string
    verificationHash*: string
    timestamp*: int64

proc newSecureSSOPayload*(userDataJsonBase64, verificationHash: string, timestamp: int64): SecureSSOPayload =
  ## Create a new SecureSSOPayload instance
  SecureSSOPayload(
    userDataJsonBase64: userDataJsonBase64,
    verificationHash: verificationHash,
    timestamp: timestamp
  )

proc toJSON*(self: SecureSSOPayload): string =
  ## Convert to JSON string
  let obj = %* {
    "timestamp": self.timestamp,
    "user_data_json_base64": self.userDataJsonBase64,
    "verification_hash": self.verificationHash
  }
  result = $obj
