import unittest
import std/[os, times, strutils, options, httpclient, json, tables]
import ../src/fastcomments/sso
import ../client/fastcomments
import ../client/fastcomments/apis/api_public
import ../client/fastcomments/apis/api_default
import ../client/fastcomments/models/model_comment_data
import ../client/fastcomments/models/model_api_status
import ../client/fastcomments/models/model_record_string_string_or_number_value
import ../client/fastcomments/models/model_get_comments_public200response
import ../client/fastcomments/models/model_get_comments200response

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
  return (getTime().toUnixFloat() * 1000).int64

suite "SSO Integration Tests":
  var client: HttpClient

  setup:
    client = newHttpClient()

  teardown:
    client.close()

  test "PublicAPI with no SSO":
    let tenantID = getTenantID()

    let (response, httpResponse) = getCommentsPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = "sdk-test-page",
      page = 0,
      direction = SortDirections.NF,
      sso = "",
      skip = 0,
      skipChildren = 0,
      limit = 0,
      limitChildren = 0,
      countChildren = false,
      fetchPageForCommentId = "",
      includeConfig = false,
      countAll = false,
      includei10n = false,
      locale = "",
      modules = "",
      isCrawler = false,
      includeNotificationCount = false,
      asTree = false,
      maxTreeDepth = 0,
      useFullTranslationIds = false,
      parentId = "",
      searchText = "",
      hashTags = @[],
      userId = "",
      customConfigStr = "",
      afterCommentId = "",
      beforeCommentId = ""
    )

    check httpResponse.code == Http200
    check response.isSome
    if response.isSome:
      let resp = response.get()
      check resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant
      if resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant:
        check resp.GetCommentsResponseWithPresence_PublicComment_Value.status == "success"

  test "PublicAPI with secure SSO":
    let apiKey = getAPIKey()
    let tenantID = getTenantID()
    let timestamp = getTimestamp()

    let user = newSecureSSOUserData(
      userId = "test-user-" & $timestamp,
      email = "test-" & $timestamp & "@example.com",
      username = "testuser" & $timestamp,
      avatar = "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey = apiKey, secureUserData = user)
    let token = sso.createToken()

    # Create a comment
    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = "sdk-test-nim"
    commentData.comment = "Test from Nim SDK"
    commentData.commenterName = user.username
    commentData.date = some(timestamp)
    commentData.meta = some(newJObject())
    commentData.questionValues = some(initTable[string, RecordStringStringOrNumberValue]())

    let (createResponse, createHttpResponse) = createCommentPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = "sdk-test-nim",
      broadcastId = "test-" & $timestamp,
      commentData = commentData,
      sessionId = "",
      sso = token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome

    # Fetch comments
    let (getResponse, getHttpResponse) = getCommentsPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = "sdk-test-nim",
      page = 0,
      direction = SortDirections.NF,
      sso = token,
      skip = 0,
      skipChildren = 0,
      limit = 0,
      limitChildren = 0,
      countChildren = false,
      fetchPageForCommentId = "",
      includeConfig = false,
      countAll = false,
      includei10n = false,
      locale = "",
      modules = "",
      isCrawler = false,
      includeNotificationCount = false,
      asTree = false,
      maxTreeDepth = 0,
      useFullTranslationIds = false,
      parentId = "",
      searchText = "",
      hashTags = @[],
      userId = "",
      customConfigStr = "",
      afterCommentId = "",
      beforeCommentId = ""
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome
    if getResponse.isSome:
      let resp = getResponse.get()
      check resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant
      if resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant:
        check resp.GetCommentsResponseWithPresence_PublicComment_Value.comments.len >= 1

  test "DefaultAPI with API key - Fetch Comments":
    let apiKey = getAPIKey()
    let tenantID = getTenantID()
    let timestamp = getTimestamp()
    let testUrlId = "sdk-test-nim-defaultapi-" & $timestamp

    # Step 1: Create a comment using PUBLIC API with SSO
    echo "Step 1: Creating test comment with PUBLIC API + SSO..."

    let user = newSecureSSOUserData(
      userId = "test-user-" & $timestamp,
      email = "test-" & $timestamp & "@example.com",
      username = "testuser" & $timestamp,
      avatar = "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey = apiKey, secureUserData = user)
    let token = sso.createToken()

    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = testUrlId
    commentData.comment = "Test from Nim SDK at " & $timestamp
    commentData.commenterName = user.username
    commentData.date = some(timestamp)
    commentData.meta = some(newJObject())
    commentData.questionValues = some(initTable[string, RecordStringStringOrNumberValue]())

    let (createResponse, createHttpResponse) = createCommentPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = testUrlId,
      broadcastId = "test-" & $timestamp,
      commentData = commentData,
      sessionId = "",
      sso = token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome
    echo "✓ Comment created successfully"

    # Step 2: Fetch comments using AUTHENTICATED DefaultAPI with API key
    echo "Step 2: Fetching comments with DefaultAPI using API key authentication..."

    var authClient = newHttpClient()
    authClient.headers["x-api-key"] = apiKey

    let (getResponse, getHttpResponse) = getComments(
      httpClient = authClient,
      tenantId = tenantID,
      page = 0,
      limit = 0,
      skip = 0,
      asTree = false,
      skipChildren = 0,
      limitChildren = 0,
      maxTreeDepth = 0,
      urlId = testUrlId,
      userId = "",
      anonUserId = "",
      contextUserId = "",
      hashTag = "",
      parentId = "",
      direction = SortDirections.NF
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome

    if getResponse.isSome:
      let resp = getResponse.get()
      check resp.kind == GetComments200responseKind.APIGetCommentsResponseVariant
      if resp.kind == GetComments200responseKind.APIGetCommentsResponseVariant:
        check resp.APIGetCommentsResponseValue.status == APIStatus.SUCCESS
        echo "✓ Retrieved ", resp.APIGetCommentsResponseValue.comments.len, " comments with DefaultAPI"
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
      userId = "test-user-" & $timestamp,
      email = "test-" & $timestamp & "@example.com",
      username = "testuser" & $timestamp,
      avatar = "https://example.com/avatar.jpg"
    )

    let sso = newSecure(apiKey = apiKey, secureUserData = user)
    let token = sso.createToken()

    var commentData = CommentData()
    commentData.url = "https://example.com/test-page"
    commentData.urlId = testUrlId
    commentData.comment = "Test from Nim SDK at " & $timestamp
    commentData.commenterName = user.username
    commentData.date = some(timestamp)
    commentData.meta = some(newJObject())
    commentData.questionValues = some(initTable[string, RecordStringStringOrNumberValue]())

    let (createResponse, createHttpResponse) = createCommentPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = testUrlId,
      broadcastId = "test-" & $timestamp,
      commentData = commentData,
      sessionId = "",
      sso = token
    )

    check createHttpResponse.code == Http200
    check createResponse.isSome
    echo "✓ Comment created successfully"

    # Step 2: Fetch the comment back using PUBLIC API with SSO
    echo "Step 2: Fetching comments for page '", testUrlId, "' with SSO..."

    let (getResponse, getHttpResponse) = getCommentsPublic(
      httpClient = client,
      tenantId = tenantID,
      urlId = testUrlId,
      page = 0,
      direction = SortDirections.NF,
      sso = token,
      skip = 0,
      skipChildren = 0,
      limit = 0,
      limitChildren = 0,
      countChildren = false,
      fetchPageForCommentId = "",
      includeConfig = false,
      countAll = false,
      includei10n = false,
      locale = "",
      modules = "",
      isCrawler = false,
      includeNotificationCount = false,
      asTree = false,
      maxTreeDepth = 0,
      useFullTranslationIds = false,
      parentId = "",
      searchText = "",
      hashTags = @[],
      userId = "",
      customConfigStr = "",
      afterCommentId = "",
      beforeCommentId = ""
    )

    check getHttpResponse.code == Http200
    check getResponse.isSome

    if getResponse.isSome:
      let resp = getResponse.get()
      check resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant

      if resp.kind == GetCommentsPublic200responseKind.GetCommentsResponseWithPresencePublicCommentVariant:
        let successResp = resp.GetCommentsResponseWithPresence_PublicComment_Value

        # Verify no error code
        check successResp.code.isNone or successResp.code.get() == ""

        # Verify comments are present
        check successResp.comments.len >= 1
        echo "✓ Retrieved ", successResp.comments.len, " comments"

        # Verify we can find our comment
        var foundOurComment = false
        for comment in successResp.comments:
          # Check that _id field is properly returned and not empty
          check comment.id != ""
          echo "✓ Comment has valid _id: ", comment.id

          if comment.commentHTML != "":
            let commentText = comment.commentHTML
            if $timestamp in commentText:
              foundOurComment = true
              echo "✓ Found our comment: ", commentText
              break

        check foundOurComment
      echo "✓ Successfully verified end-to-end create and fetch with SSO authentication"
