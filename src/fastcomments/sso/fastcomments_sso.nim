import std/[options, times]
import helpers, secure_sso_payload, secure_sso_user_data, simple_sso_user_data

type
  FastCommentsSSO* = object
    secureSSOPayload: Option[SecureSSOPayload]
    simpleSSOUserData: Option[SimpleSSOUserData]
    loginUrl: Option[string]
    logoutUrl: Option[string]
    cachedToken: Option[string]

proc newSecure*(apiKey: string, secureUserData: SecureSSOUserData): FastCommentsSSO =
  ## Create a new FastCommentsSSO instance with secure SSO
  let timestamp = getTime().toUnix()
  let userDataStr = secureUserData.asJsonBase64()
  let hash = createVerificationHash(apiKey, timestamp, userDataStr)

  let payload = newSecureSSOPayload(userDataStr, hash, timestamp)

  result = FastCommentsSSO(
    secureSSOPayload: some(payload),
    simpleSSOUserData: none(SimpleSSOUserData),
    loginUrl: none(string),
    logoutUrl: none(string),
    cachedToken: none(string)
  )

proc newSimple*(simpleUserData: SimpleSSOUserData): FastCommentsSSO =
  ## Create a new FastCommentsSSO instance with simple SSO
  result = FastCommentsSSO(
    secureSSOPayload: none(SecureSSOPayload),
    simpleSSOUserData: some(simpleUserData),
    loginUrl: none(string),
    logoutUrl: none(string),
    cachedToken: none(string)
  )

proc newSecureWithUrls*(securePayload: SecureSSOPayload, loginUrl, logoutUrl: string): FastCommentsSSO =
  ## Create a new FastCommentsSSO instance with secure SSO and URLs
  result = FastCommentsSSO(
    secureSSOPayload: some(securePayload),
    simpleSSOUserData: none(SimpleSSOUserData),
    loginUrl: some(loginUrl),
    logoutUrl: some(logoutUrl),
    cachedToken: none(string)
  )

proc createToken*(self: FastCommentsSSO): string =
  ## Create an SSO token
  if self.secureSSOPayload.isSome:
    return self.secureSSOPayload.get().toJSON()
  elif self.simpleSSOUserData.isSome:
    return self.simpleSSOUserData.get().toJSON()
  else:
    raise newException(ValueError, "No user data provided")

proc resetToken*(self: var FastCommentsSSO) =
  ## Reset the cached token
  self.cachedToken = none(string)

proc prepareToSend*(self: var FastCommentsSSO): string =
  ## Prepare the token to send (uses cached token if available)
  if self.cachedToken.isSome:
    return self.cachedToken.get()

  let token = self.createToken()
  self.cachedToken = some(token)
  return token

proc setSecureSSOPayload*(self: var FastCommentsSSO, payload: SecureSSOPayload) =
  ## Set the secure SSO payload
  self.secureSSOPayload = some(payload)
  self.simpleSSOUserData = none(SimpleSSOUserData)
  self.resetToken()

proc setSimpleSSOUserData*(self: var FastCommentsSSO, userData: SimpleSSOUserData) =
  ## Set the simple SSO user data
  self.simpleSSOUserData = some(userData)
  self.secureSSOPayload = none(SecureSSOPayload)
  self.resetToken()

proc getLoginUrl*(self: FastCommentsSSO): Option[string] =
  ## Get the login URL
  return self.loginUrl

proc getLogoutUrl*(self: FastCommentsSSO): Option[string] =
  ## Get the logout URL
  return self.logoutUrl
