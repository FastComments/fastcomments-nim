import unittest
import std/[json, base64, times]
import ../src/fastcomments/sso

const
  API_KEY = "test-api-key-12345"
  USER_ID = "test-user-123"
  EMAIL = "test@example.com"
  USERNAME = "testuser"
  AVATAR = "https://example.com/avatar.jpg"

suite "SSO Helpers Tests":
  test "CreateVerificationHash":
    let timestamp = getTime().toUnix()
    let userData = "test_data_base64"

    let result = createVerificationHash(
      apiKey = API_KEY,
      timestamp = timestamp,
      userDataJsonBase64 = userData
    )

    check result.len > 0
    check result.len == 64

suite "SecureSSOUserData Tests":
  test "CreateUserData":
    let user = newSecureSSOUserData(
      userId = USER_ID,
      email = EMAIL,
      username = USERNAME,
      avatar = AVATAR
    )

    check user.userId == USER_ID
    check user.email == EMAIL
    check user.username == USERNAME
    check user.avatar == AVATAR

suite "SimpleSSOUserData Tests":
  test "CreateUserData":
    let user = newSimpleSSOUserData(
      userId = USER_ID,
      email = EMAIL,
      avatar = AVATAR
    )

    check user.userId == USER_ID
    check user.email == EMAIL
    check user.avatar == AVATAR

suite "FastCommentsSSO Tests":
  test "CreateSecureSSO":
    let user = newSecureSSOUserData(
      userId = USER_ID,
      email = EMAIL,
      username = USERNAME,
      avatar = AVATAR
    )
    let sso = newSecure(apiKey = API_KEY, secureUserData = user)

    let token = sso.createToken()
    check token.len > 0

  test "CreateSimpleSSO":
    let user = newSimpleSSOUserData(
      userId = USER_ID,
      email = EMAIL,
      avatar = AVATAR
    )
    let sso = newSimple(simpleUserData = user)

    let token = sso.createToken()
    check token.len > 0
