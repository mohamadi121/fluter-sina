# NOTES.md — working decisions & discovered mismatches

## AuthSession is the single owner of the token
`lib/core/auth/auth_session.dart` (ChangeNotifier) is the only component
allowed to touch token storage. DioClient reads it synchronously, GoRouter
uses it as refreshListenable for the auth guard, AuthBloc/SplashBloc consume
it. On any 401 the session clears itself and the router redirects to login —
never re-implement per-screen token reads (`SecureStorage.readSecureStorage`)
in new code; the legacy helper remains only for `market_id`.

## Backend has TWO error envelope shapes — handle both
Hand-built `ApiResponse`: `{success, code, error: {code, detail} | "<string>"}`.
DRF-raised exceptions go through `apps/core/exception_handler.py`:
`{error: true, code, message, details, original_error}` (401/429/serializer
400s). `_envelopeDetail` in api_status.dart handles all shapes — keep it that
way when touching error handling.

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

## Graphify is installed and both repos are in the shared graph
Graphify 0.9.13 was installed on 2026-07-12. Both repos have project-scoped
Claude integration, fresh code-only graphs under their local `graphify-out/`
directories, and are registered in the global graph as `backend` and `frontend`.
The generated graph artifacts are intentionally gitignored because they are
large and reproducible; keep the project integration in version control and
run `graphify update .` after code changes.

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

## Android build needs AGP 8.9.1 (was 8.7.3) — plugins pull bleeding-edge AndroidX
`flutter build apk` failed at `checkDebugAarMetadata`: transitive AndroidX deps
(core 1.18.0, activity 1.12.4, browser 1.9.0, navigationevent) required AGP
8.9.1+. Bumped AGP in `android/settings.gradle.kts`. Constraints already met:
Gradle 8.14, Kotlin 2.1.0, compileSdk/targetSdk 36 (Flutter 3.44), JDK 17.
CI pins JDK 17 via actions/setup-java. If a plugin later needs an even newer
AGP, bump again — don't pin the AndroidX deps down.

## Chat is WebSocket-first; backend WS had two blockers (both fixed)
Backend chat has a working REST API (Token) AND a Channels WebSocket. The WS
was unusable: (1) routing captured `room_name` but ChatConsumer reads
`room_id` → KeyError → close on every connect; (2) WS auth was session-cookie
only, but the app uses Token. Fixed in backend: routing → `room_id`, and
`apps/core/ws_auth.TokenAuthMiddleware` (reads `?token=`/Authorization, sets
scope['user']) wired inside AuthMiddlewareStack in `config/asgi.py`. Frontend
connects `ws(s)://host/ws/chat/<room_id>/?token=<key>`. Support tickets reuse
the normal chat room (a ticket spawns `chat_room_id`). Message shapes differ
between REST (sender/created_at) and WS (sender_id/sent_at) — ChatMessageModel
tolerates both. currentUserId comes from the `connection_established` frame
(the app never learns its own user id otherwise — pin/verify returns only a
token). Backend runtime (Channels/ASGI) can't be run here (Linux venv), so the
WS path is verified by contract + unit tests, not a live socket.

## SSL private key committed in backend repo
`ssl/asoud.key` is tracked in git. Cleanup batch: stop mounting from repo,
gitignore, document rotation. History rewrite / key rotation on the server is
the owner's call (affects production).

## The batch-13 "final audit" was not a complete fake-code audit
A 2026-07-12 rescan found duplicate empty CartBloc/PaymentBloc trees, unused
empty ProfileBloc, a CustomerBloc that returned synthetic `Success()` values,
and catch-all no-op handlers inside active product/market blocs. Batch 14 removes
those artifacts plus fake business-card location persistence without touching
the real cart/payment implementations. Several
dead UI callbacks and incomplete owner-side feature surfaces still remain; do
not treat the v1.1.0 tag as full backend/frontend feature parity.

## SECURITY: new UI must not expose unsafe backend admin/business paths
The resumed audit found three backend blockers: analytics returns platform-wide
data to ordinary authenticated users, notification create accepts an arbitrary
target user without an admin permission, and SMS send bypasses billing with a
hardcoded `WALLET_OK = True`. These need explicit product/authorization decisions
before their full Flutter surfaces are enabled. The existing notification inbox
is safe to keep because it only lists and marks the current user's notifications.
