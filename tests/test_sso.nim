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

    let result = createVerificationHash(API_KEY, timestamp, userData)

    check result.len > 0
    check result.len == 64

suite "SecureSSOUserData Tests":
  test "CreateUserData":
    let user = newSecureSSOUserData(USER_ID, EMAIL, USERNAME, AVATAR)

    check user.userId == USER_ID
    check user.email == EMAIL
    check user.username == USERNAME
    check user.avatar == AVATAR

suite "SimpleSSOUserData Tests":
  test "CreateUserData":
    let user = newSimpleSSOUserData(USER_ID, EMAIL, AVATAR)

    check user.userId == USER_ID
    check user.email == EMAIL
    check user.avatar == AVATAR

suite "FastCommentsSSO Tests":
  test "CreateSecureSSO":
    let user = newSecureSSOUserData(USER_ID, EMAIL, USERNAME, AVATAR)
    let sso = newSecure(API_KEY, user)

    let token = sso.createToken()
    check token.len > 0

  test "CreateSimpleSSO":
    let user = newSimpleSSOUserData(USER_ID, EMAIL, AVATAR)
    let sso = newSimple(user)

    let token = sso.createToken()
    check token.len > 0
