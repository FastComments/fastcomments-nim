import std/[json, base64]

type
  SecureSSOUserData* = object
    userId*: string
    email*: string
    username*: string
    avatar*: string

proc newSecureSSOUserData*(userId, email, username, avatar: string): SecureSSOUserData =
  ## Create a new SecureSSOUserData instance
  SecureSSOUserData(
    userId: userId,
    email: email,
    username: username,
    avatar: avatar
  )

proc toJSON*(self: SecureSSOUserData): string =
  ## Convert to JSON string
  let obj = %* {
    "avatar": self.avatar,
    "email": self.email,
    "user_id": self.userId,
    "username": self.username
  }
  result = $obj

proc asJsonBase64*(self: SecureSSOUserData): string =
  ## Convert to base64-encoded JSON string
  let jsonStr = self.toJSON()
  result = encode(jsonStr)
