import std/json

type
  SimpleSSOUserData* = object
    userId*: string
    email*: string
    avatar*: string

proc newSimpleSSOUserData*(userId, email, avatar: string): SimpleSSOUserData =
  ## Create a new SimpleSSOUserData instance
  SimpleSSOUserData(
    userId: userId,
    email: email,
    avatar: avatar
  )

proc toJSON*(self: SimpleSSOUserData): string =
  ## Convert to JSON string
  let obj = %* {
    "avatar": self.avatar,
    "email": self.email,
    "user_id": self.userId
  }
  result = $obj
