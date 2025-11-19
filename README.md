# fastcomments-nim
The FastComments Nim SDK. You can use this to build secure and scalable backend applications that interact with FastComments, or build reactive client applications.

## Requirements

- Nim >= 1.6.0
- nimcrypto >= 0.5.4

## Installation

### Using Nimble

```bash
nimble install fastcomments
```

### Building from Source

```bash
nimble build
```

### Library Contents

This library contains the generated API client and the SSO utilities to make working with the API easier.

- [API Client Library Docs](./client/README.md)

### Public vs Secured APIs

For the API client, there are two API modules, `api_default` and `api_public`. The `api_default` contains methods that require your API key, and `api_public` contains api calls
that can be made directly from a browser/mobile device/etc without authentication.

## Quick Start

### Using Authenticated APIs (DefaultAPI)

**Important:** Authenticated endpoints require your API key to be set as the `x-api-key` header.

```nim
import httpclient
import fastcomments
import fastcomments/apis/api_default
import fastcomments/models/model_comment_data

let client = newHttpClient()
client.headers["x-api-key"] = "your-api-key"

# Make authenticated API calls
let (response, httpResponse) = getComments(
  httpClient = client,
  tenantId = "your-tenant-id",
  page = 0,
  limit = 0,
  skip = 0,
  asTree = false,
  skipChildren = 0,
  limitChildren = 0,
  maxTreeDepth = 0,
  urlId = "your-url-id",
  userId = "",
  anonUserId = "",
  contextUserId = "",
  hashTag = "",
  parentId = "",
  direction = SortDirections.DESC
)

if response.isSome:
  let resp = response.get()
  if resp.comments.isSome:
    echo "Found ", resp.comments.get().len, " comments"
```

### Using Public APIs (PublicAPI)

Public endpoints don't require authentication:

```nim
import httpclient
import fastcomments
import fastcomments/apis/api_public

let client = newHttpClient()

# Make public API calls
let (response, httpResponse) = getCommentsPublic(
  httpClient = client,
  tenantId = "your-tenant-id",
  urlId = "your-url-id",
  page = 0,
  direction = SortDirections.DESC,
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

if response.isSome:
  let resp = response.get()
  if resp.comments.isSome:
    echo "Found ", resp.comments.get().len, " comments"
```

### Common Issues

1. **401 authentication error**: Make sure you set the `x-api-key` header on your HttpClient before making DefaultAPI requests: `client.headers["x-api-key"] = "your-api-key"`
2. **Wrong API class**: Use `api_default` for server-side authenticated requests, `api_public` for client-side/public requests.

## Making API Calls

All API methods in this SDK return tuples of `(Option[ResponseType], Response)`. The first element contains the parsed response if successful, and the second element is the raw HTTP response.

### Example: Fetching Comments

```nim
import httpclient
import options
import fastcomments
import fastcomments/apis/api_default

let client = newHttpClient()
client.headers["x-api-key"] = "your-api-key"

let (response, httpResponse) = getComments(
  httpClient = client,
  tenantId = "your-tenant-id",
  page = 0,
  limit = 0,
  skip = 0,
  asTree = false,
  skipChildren = 0,
  limitChildren = 0,
  maxTreeDepth = 0,
  urlId = "your-url-id",
  userId = "",
  anonUserId = "",
  contextUserId = "",
  hashTag = "",
  parentId = "",
  direction = SortDirections.DESC
)

if httpResponse.code == Http200:
  if response.isSome:
    let resp = response.get()
    if resp.comments.isSome:
      echo "Found ", resp.comments.get().len, " comments"
```

## Notes

### Broadcast Ids

You'll see you're supposed to pass a `broadcastId` in some API calls. When you receive events, you'll get this ID back, so you know to ignore the event if you plan to optimistically apply changes on the client
(which you'll probably want to do since it offers the best experience). Pass a UUID here. The ID should be unique enough to not occur twice in a browser session.

### SSO (Single Sign-On)

For SSO examples, see below.

## SSO Usage

### Simple SSO

```nim
import fastcomments/sso

let user = newSimpleSSOUserData(
  userId = "user-123",
  email = "user@example.com",
  avatar = "https://example.com/avatar.jpg"
)
let sso = newSimple(simpleUserData = user)
let token = sso.createToken()

echo "SSO Token: ", token
```

### Secure SSO

```nim
import fastcomments/sso

let user = newSecureSSOUserData(
  userId = "user-123",
  email = "user@example.com",
  username = "johndoe",
  avatar = "https://example.com/avatar.jpg"
)

let apiKey = "your-api-key"
let sso = newSecure(apiKey = apiKey, secureUserData = user)
let token = sso.createToken()

echo "Secure SSO Token: ", token
```

## Testing

Set the required environment variables:

```bash
export FASTCOMMENTS_API_KEY="your-api-key"
export FASTCOMMENTS_TENANT_ID="your-tenant-id"
```

Run the tests:

```bash
nimble test
```

Or run specific tests:

```bash
nim c -r tests/test_sso.nim
nim c -r tests/test_sso_integration.nim
```

## Development

To update the generated client from the OpenAPI spec:

```bash
./update.sh
```

## License

MIT License - see LICENSE file for details

## Support

For support, please visit https://fastcomments.com/auth/my-account/help or email support@fastcomments.com
