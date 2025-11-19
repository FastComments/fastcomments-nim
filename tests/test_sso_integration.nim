import unittest
import std/[os, times, strutils, options, httpclient]
import ../src/fastcomments/sso
import ../client/fastcomments
import ../client/fastcomments/apis/api_public
import ../client/fastcomments/apis/api_default
import ../client/fastcomments/models/model_comment_data
import ../client/fastcomments/models/model_api_status
import ../client/config

proc getAPIKey(): string =
  let apiKey = getEnv("FASTCOMMENTS_API_KEY")
  if apiKey == "":
    raise newException(ValueError, "FASTCOMMENTS_API_KEY environment variable is required")
  return apiKey

proc getTenantID(): string =
  let tenantId = getEnv("FASTCOMMENTS_TENANT_ID")
  if tenantId == "":
    raise newException(ValueError, "FASTCOMMENTS_TENANT_ID environment variable is required")
  return tenantId

proc getTimestamp(): int64 =
  return getTime().toUnixFloat().int64

suite "SSO Integration Tests":
  var client: HttpClient

  setup:
    client = newHttpClient()
    client.headers["User-Agent"] = config.useragent

  teardown:
    client.close()

  test "PublicAPI with no SSO":
    let tenantID = getTenantID()

    let (response, httpResponse) = client.getCommentsPublic(
      tenantID,
      "sdk-test-page",
      0, SortDirections.NF, "", 0, 0, 0, 0, false, "", false, false, false, "",
      "", false, false, false, 0, false, "", "", @[], "", "", "", ""
    )

    check httpResponse.code == Http200
    check response.isSome

  test "PublicAPI with secure SSO":
    let apiKey = getAPIKey()
    let tenantID = getTenantID()
    let timestamp = getTimestamp()

    let user = newSecureSSOUserData(
      "test-user-" & $timestamp,
      "test-" & $timestamp & "@example.com",
      "testuser" & $timestamp,
      "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey, user)
    let token = sso.createToken()

    # Create a comment
    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = "sdk-test-nim"
    commentData.comment = "Test from Nim SDK"
    commentData.commenterName = user.username
    commentData.date = timestamp

    let (createResponse, createHttpResponse) = client.createCommentPublic(
      tenantID,
      "sdk-test-nim",
      "test-" & $timestamp,
      commentData,
      "",
      token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome

    # Fetch comments
    let (getResponse, getHttpResponse) = client.getCommentsPublic(
      tenantID,
      "sdk-test-nim",
      0, SortDirections.NF, token, 0, 0, 0, 0, false, "", false, false, false, "",
      "", false, false, false, 0, false, "", "", @[], "", "", "", ""
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome
    if getResponse.isSome:
      let resp = getResponse.get()
      check resp.comments.len >= 1

  test "DefaultAPI with API key - Fetch Comments":
    let apiKey = getAPIKey()
    let tenantID = getTenantID()
    let timestamp = getTimestamp()
    let testUrlId = "sdk-test-nim-defaultapi-" & $timestamp

    # Step 1: Create a comment using PUBLIC API with SSO
    echo "Step 1: Creating test comment with PUBLIC API + SSO..."

    let user = newSecureSSOUserData(
      "test-user-" & $timestamp,
      "test-" & $timestamp & "@example.com",
      "testuser" & $timestamp,
      "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey, user)
    let token = sso.createToken()

    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = testUrlId
    commentData.comment = "Test from Nim SDK at " & $timestamp
    commentData.commenterName = user.username
    commentData.date = timestamp

    let (createResponse, createHttpResponse) = client.createCommentPublic(
      tenantID,
      testUrlId,
      "test-" & $timestamp,
      commentData,
      "",
      token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome
    echo "✓ Comment created successfully"

    # Step 2: Fetch comments using AUTHENTICATED DefaultAPI with API key
    echo "Step 2: Fetching comments with DefaultAPI using API key authentication..."

    var authClient = newHttpClient()
    authClient.headers["User-Agent"] = config.useragent
    authClient.headers["api_key"] = apiKey

    let (getResponse, getHttpResponse) = authClient.getComments(
      tenantID,
      0, 0, 0, false, 0, 0, 0, testUrlId, "", "", "", "", "", SortDirections.NF
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome

    if getResponse.isSome:
      let resp = getResponse.get()
      check resp.status == APIStatus.SUCCESS
      check resp.comments.len >= 1
      echo "✓ Retrieved ", resp.comments.len, " comments with DefaultAPI"
      echo "✓ Successfully verified DefaultAPI authentication with API key works!"

    authClient.close()

  test "PublicAPI - Create and Fetch Comment with SSO (End-to-End Test)":
    let apiKey = getAPIKey()
    let tenantID = getTenantID()
    let timestamp = getTimestamp()
    let testUrlId = "sdk-test-nim-create-fetch-" & $timestamp

    # Step 1: Create a comment using PUBLIC API with SSO
    echo "Step 1: Creating comment with PUBLIC API + SSO..."

    let user = newSecureSSOUserData(
      "test-user-" & $timestamp,
      "test-" & $timestamp & "@example.com",
      "testuser" & $timestamp,
      "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey, user)
    let token = sso.createToken()

    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = testUrlId
    commentData.comment = "Test from Nim SDK at " & $timestamp
    commentData.commenterName = user.username
    commentData.date = timestamp

    let (createResponse, createHttpResponse) = client.createCommentPublic(
      tenantID,
      testUrlId,
      "test-" & $timestamp,
      commentData,
      "",
      token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome
    echo "✓ Comment created successfully"

    # Step 2: Fetch the comment back using PUBLIC API with SSO
    echo "Step 2: Fetching comments for page '", testUrlId, "' with SSO..."

    let (getResponse, getHttpResponse) = client.getCommentsPublic(
      tenantID,
      testUrlId,
      0, SortDirections.NF, token, 0, 0, 0, 0, false, "", false, false, false, "",
      "", false, false, false, 0, false, "", "", @[], "", "", "", ""
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome

    if getResponse.isSome:
      let resp = getResponse.get()

      # Verify no error code
      check resp.code == ""

      # Verify comments are present
      check resp.comments.len >= 1
      echo "✓ Retrieved ", resp.comments.len, " comments"

      # Verify we can find our comment
      var foundOurComment = false
      for comment in resp.comments:
        if comment.commentHTML != "":
          let commentText = comment.commentHTML
          if $timestamp in commentText:
            foundOurComment = true
            echo "✓ Found our comment: ", commentText
            break

      check foundOurComment
      echo "✓ Successfully verified end-to-end create and fetch with SSO authentication"
