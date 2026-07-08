# NOTES.md — working decisions & discovered mismatches

## Auth: backend is DRF Token, not JWT — align frontend, not backend
Backend (`config/settings/base.py:387`) uses `TokenAuthentication`; pin/verify
returns `data.token`. Frontend was written against an imagined JWT contract
(Bearer header, refresh/logout endpoints, `data.jwt.access`). Decision: strip
JWT logic from frontend, send `Authorization: Token <key>`, remove refresh
interceptor. Backend's own FRONTEND_CHECKLIST.md confirms the Token scheme.

## ALL_ENDPOINTS.txt is approximate — trust urls.py only
Example: cart routes are slash-less in `apps/cart/urls/user.py` but listed with
trailing slashes in ALL_ENDPOINTS.txt. Verify every path/method against the
app's `urls.py` + view before wiring.

## graphify was never installed
User instructions assumed a prebuilt graphify graph over both repos; no graph or
GRAPH_REPORT.md exists and the tool is not on PATH. Exploration done directly
(grep/read). If graphify gets installed later, regenerate the map from it.

## Payment "pay" endpoint is a browser redirect, not an API call
`GET user/payments/pay` (AllowAny) is the Zarinpal redirect URL. The app must
open it in a browser/WebView with the payment id — not POST to it via dio
(current code does the latter and the WebView TODO was never implemented).

## Frontend architecture is inconsistent by layer
Some features: data_source → repository → bloc (auth, create_workspace, market).
Others: bloc holds ApiService directly (cart, wallet, payment). Ten blocs are
empty shells. Keep the repository pattern where it exists; don't force-refactor
working direct-service blocs unless touched for another reason.

## Raw-http shadow layer bypasses DioClient (found in batch 0)
Ten screens/widgets call the API with `package:http` and `Bearer $token` —
broken since day one and invisible to any dio-level fix. One (`terms_conditions`)
also had a real DRF token hardcoded (removed; token should be revoked server-side).
Migration happens per-batch — see ARCHITECTURE_MAP.md §2.5b. When auditing a
feature, always grep for `package:http` too, not just DioClient usage.

## Terms endpoint needed a backend fix, not a frontend workaround
`GET info/term/` inherited `IsAuthenticated`; the signup flow needs it pre-login.
Fixed in backend with `AllowAny` (apps/information/views/user_views.py) instead
of keeping the hardcoded-token hack in the app.

## SSL private key committed in backend repo
`ssl/asoud.key` is tracked in git. Cleanup batch: stop mounting from repo,
gitignore, document rotation. History rewrite / key rotation on the server is
the owner's call (affects production).
