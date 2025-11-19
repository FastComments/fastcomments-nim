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

**Important:**
1. You must set your API key as a header on the HttpClient before making authenticated requests. If you don't, requests will fail with a 401 error.

```nim
import httpclient
import fastcomments
import fastcomments/apis/api_default
import fastcomments/models/model_comment_data
import config

let client = newHttpClient()
client.headers["User-Agent"] = config.useragent
client.headers["api_key"] = "YOUR_API_KEY_HERE"

# Now make authenticated API calls
let (response, httpResponse) = client.getComments(
  "your-tenant-id",
  0, 0, 0, false, 0, 0, 0, "your-url-id", "", "", "", "", "", SortDirections.DESC
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
import config

let client = newHttpClient()
client.headers["User-Agent"] = config.useragent

# Make public API calls
let (response, httpResponse) = client.getCommentsPublic(
  "your-tenant-id",
  "your-url-id",
  0, SortDirections.DESC, "", 0, 0, 0, 0, false, "", false, false, false, "",
  "", false, false, false, 0, false, "", "", @[], "", "", "", ""
)

if response.isSome:
  let resp = response.get()
  if resp.comments.isSome:
    echo "Found ", resp.comments.get().len, " comments"
```

### Common Issues

1. **401 "missing-api-key" error**: Make sure you set `client.headers["api_key"] = "YOUR_KEY"` before making DefaultAPI requests.
2. **Wrong API class**: Use `api_default` for server-side authenticated requests, `api_public` for client-side/public requests.

## Making API Calls

All API methods in this SDK return tuples of `(Option[ResponseType], Response)`. The first element contains the parsed response if successful, and the second element is the raw HTTP response.

### Example: Fetching Comments

```nim
import httpclient
import options
import fastcomments
import fastcomments/apis/api_default
import config

let client = newHttpClient()
client.headers["User-Agent"] = config.useragent
client.headers["api_key"] = "your-api-key"

let (response, httpResponse) = client.getComments(
  "your-tenant-id",
  0, 0, 0, false, 0, 0, 0, "your-url-id", "", "", "", "", "", SortDirections.DESC
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

let user = newSimpleSSOUserData("user-123", "user@example.com", "https://example.com/avatar.jpg")
let sso = newSimple(user)
let token = sso.createToken()

echo "SSO Token: ", token
```

### Secure SSO

```nim
import fastcomments/sso

let user = newSecureSSOUserData("user-123", "user@example.com", "johndoe", "https://example.com/avatar.jpg")

let apiKey = "your-api-key"
let sso = newSecure(apiKey, user)
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
