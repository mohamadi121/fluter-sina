# ARCHITECTURE_MAP.md — Asoud Product (Backend + Flutter Frontend)

> Shared reference for the production-v1 effort. Updated after every batch.
> Backend repo: `asoud-project-full` (Django, source of truth for the API contract).
> Frontend repo: `fluter-sina` (Flutter, package name `asood`).
> Last full audit: 2026-07-08 (initial map, pre-change).

## 0. Ground truth and conventions

- **API contract source of truth:** backend `config/urls.py` + per-app `urls.py` files.
  `ALL_ENDPOINTS.txt` (252 endpoints) is a useful index but NOT exact — e.g. it shows
  trailing slashes on cart routes that the real `apps/cart/urls/user.py` does not have.
  Always verify against `urls.py` before wiring.
- **Auth (backend reality):** DRF `TokenAuthentication` + `SessionAuthentication`
  (`config/settings/base.py:387`). Login flow: `POST user/pin/create/` →
  `POST user/pin/verify/` → returns `data: {token: <DRF key>}`.
  Correct header: `Authorization: Token <key>` (confirmed by backend's own
  `FRONTEND_CHECKLIST.md`). There is a custom JWT class in
  `apps/users/authentication.py` but it is NOT enabled (commented out in settings).
- **Response envelope:** `{success, code, data, message}` on success,
  `{success, code, error: {code, detail}}` on failure. Frontend `apiStatus()` in
  `lib/core/http_client/api_status.dart` already matches this.
- **Frontend stack:** flutter_bloc + get_it (`lib/locator.dart`) + dio
  (`lib/core/http_client/api_client.dart`) + go_router (29 routes,
  `lib/core/router/`). Base URL: `Endpoints.baseUrl` via `--dart-define
  API_BASE_URL`, default `https://asoud.ir/api/v1/`.

## 1. CRITICAL cross-cutting breakages (block everything else)

| # | Problem | Where | Effect |
|---|---------|-------|--------|
| C1 | Frontend sends `Authorization: Bearer <token>`; backend only accepts `Token <key>` | `api_client.dart:31` | Every authenticated request returns 401. The app cannot work against this backend at all. |
| C2 | Frontend calls `user/jwt/refresh/` and `user/jwt/logout/` — endpoints do not exist in backend | `api_client.dart:49`, `auth_api_service.dart` (`Endpoints.jwtRefresh/jwtLogout`) | 401 handler tries refresh → 404 → wipes stored token → user silently logged out on first auth'd call. |
| C3 | Login response parsing expects `data.jwt.access/refresh` which backend never returns (falls back to `data.token`, which works by accident) | `auth_api_service.dart:verifyUser` | Dead code masking the real contract; refresh token never exists. |
| C4 | `Endpoints.logout = "logout/"` and `Endpoints.userContact = 'contact/'` do not exist in backend | `endpoints.dart:19,23` | 404. |
| C5 | No logging framework in frontend — only `print`/`debugPrint`/`log`, and every data-source swallows all exceptions into a generic `Failure(301, 'عدم برقراری ارتباط با سرور')` | all `*_api_service.dart`, `api_status.dart` | Production errors are untraceable; real HTTP errors indistinguishable from network loss. |

**Fix direction (decided):** align frontend to backend's DRF Token scheme
(`Token <key>`, no refresh flow, drop jwt endpoints). Backend stays untouched —
it is the contract.

## 2. Endpoint ↔ frontend map (by backend domain)

Legend: **OK** wired & path/method match · **WRONG** wired but mismatched ·
**ABSENT** backend feature with no real frontend usage · **SHELL** frontend UI
exists but connected to nothing.

### 2.1 Auth / users (`api/v1/user/`)
| Backend | Frontend | Status |
|---|---|---|
| `POST user/pin/create/` | `AuthApiService.userAuth` | OK |
| `POST user/pin/verify/` | `AuthApiService.verifyUser` | OK (but see C1/C3) |
| `user/bank-info/list/`, `user/bank/info/*` (CRUD) | `bank_card` feature is UI-only, no data layer | SHELL |

### 2.2 Category (`api/v1/category/`)
| Backend | Frontend | Status |
|---|---|---|
| `group/list/`, `list/{pk}`, `sub/list/{pk}` | `job_managment` CategoryApiService | OK |
| `product-group/list/`, `product/list/{pk}`, `product/sub/list/{pk}`, `slider/image/{pk}` | — | ABSENT |

### 2.3 Market — owner (`api/v1/owner/market/`)
| Backend | Frontend | Status |
|---|---|---|
| `create/`, `list/`, `contact/create/`, `location/create/`, `schedules/create/`, `inactive/{pk}`, `queue/{pk}`, `logo/{pk}`, `background/{pk}`, `slider/{pk}`, `theme/{pk}` | `CreateMarketApiService` | OK (media-endpoint HTTP methods need per-case verify in batch) |
| `{pk}/` (detail), `update/{pk}/` | — | ABSENT (owner cannot view/edit market info → `editStoreInfo`/`storeInfo` screens are cosmetic) |
| `contact/{pk}/`, `contact/update/{pk}/`, `location/{pk}/`, `location/update/{pk}/` | — | ABSENT |
| `schedules/list/`, `schedules/{pk}/update|delete/` | — | ABSENT |
| — (no such endpoint) | `CreateMarketApiService.getMarketComments` calls `owner/market/comment/list/{id}/` | WRONG → 404. Real comments API: `user/comment/comments/{content_type}/{object_id}/` |

### 2.4 Market — user side (`api/v1/user/market/`)
| Backend | Frontend | Status |
|---|---|---|
| `public/list/` (marketplace browsing), `list/`, `schedule/{pk}/` | — | ABSENT — the entire buyer-side market browsing is missing |
| `POST/DELETE bookmark/` | `bookmarks_page.dart` renders hardcoded `[MarketModel()]` | SHELL + mock data |
| `report/{pk}/` | — | ABSENT |

### 2.5 Product (`api/v1/owner/product/`, `api/v1/products/`)
| Backend | Frontend | Status |
|---|---|---|
| `create/`, `discount/create/{pk}`, `list/{pk}`, `theme/create|list|update` | `ProductApiService` (market feature) | OK |
| `detail/{pk}/`, `ship/list|create/{pk}`, `theme/delete/{pk}` | — | ABSENT |
| `GET products/` (public search w/ filters) | — | ABSENT — buyer-side product search missing; `features/product` bloc is an empty shell |

### 2.6 Comments (`api/v1/user/comment/`)
| Backend | Frontend | Status |
|---|---|---|
| `comments/product/{id}/` (list) | `ProductApiService.getProductComments` | OK |
| `create/`, `update/{id}`, `delete/{id}`, `{id}/like/` | `CommentBloc` registered in locator but has no repository/API | SHELL |

### 2.7 Cart / orders (`api/v1/user/order/`, `api/v1/owner/order/`)
| Backend | Frontend | Status |
|---|---|---|
| user: `orders`, `add_item`, `update_item/{pk}`, `remove_item/{pk}`, `checkout`, `create`, `list`, `{pk}`, `{pk}/update`, `{pk}/delete` (no trailing slashes in backend) | `CartApiService` | OK (paths match; response-model mapping needs batch-level verify) |
| owner: `list/`, `{order_id}/`, `verify/` | — | ABSENT — seller cannot see incoming orders |

### 2.8 Payment (`api/v1/user/payments/`)
| Backend | Frontend | Status |
|---|---|---|
| `create/`, `verify/`, `` (list), `{pk}/` | `PaymentApiService` | OK |
| `GET pay` (Zarinpal redirect, `AllowAny`, browser URL) | frontend POSTs to it via dio; `payment_screen.dart:78` TODO "Open WebView" never done | WRONG — gateway never opens; payment flow cannot complete |

### 2.9 Wallet (`api/v1/wallet/`)
| Backend | Frontend | Status |
|---|---|---|
| `balance/`, `balance/check/`, `transactions/`, `pay/` | `WalletApiService` | OK (top-up navigation TODO at `wallet_screen.dart:193`) |

### 2.10 Discount (`api/v1/discount/`)
| Backend | Frontend | Status |
|---|---|---|
| owner `create/list/{id}/update/delete`, user `apply/remove/validate` | `takhfif_setting_screen` is UI-only | SHELL — discounts configured nowhere, cart never applies them |

### 2.11 Reservation (`api/v1/reservation/…` ~25 endpoints)
`features/reservation` + `features/service` = empty bloc shells (`ReservationBloc`/`ServiceBloc` with `on<Event>((e, emit) {})`). **ABSENT.**

### 2.12 Chat + support (`api/v1/chat/…` ~20 endpoints)
`features/chat` = empty `ChatBloc`, static `chat_list.dart`/`chat_page.dart`. **SHELL.** (Backend likely also exposes WebSocket — verify in batch.)

### 2.13 Notifications (`api/v1/notifications/…`)
`features/notification` = empty `NotificationBloc`. **SHELL.**

### 2.14 Advertise (`api/v1/advertisements/`)
| Backend | Frontend | Status |
|---|---|---|
| `GET advertisements/` | `AuthApiService.getAdvertises` (odd placement in auth service) | OK |
| `self/`, `{id}/`, `create/`, `payment/`, `update/`, `delete/` | — | ABSENT |

### 2.15 Affiliate (`api/v1/user|owner/affiliate/…`) — ABSENT entirely.
### 2.16 Referral (`api/v1/user/referral/`) — ABSENT entirely.
### 2.17 Region (`api/v1/region/`)
`country/province/city list` OK (create_workspace). `search/`, `details/{id}` ABSENT (fine for v1).
### 2.18 Price inquiry (`api/v1/user|owner/inquiries/`)
| Backend | Frontend | Status |
|---|---|---|
| `POST user/inquiries/create/` | `InquiryAPIService.submitInquiry` | WRONG-ish: accepts `inquiryImages` param but never uploads them (backend has separate `POST {id}/image/`); `description`/`category` params dropped |
| user `list/{id}/update/delete/send/expiry/answers`, owner `inquiries/answers` (full dashboard) | `inquiry` feature has 24 files of UI incl. dashboard screens | SHELL beyond create |
### 2.19 Analytics (`api/v1/analytics/…` ~25 endpoints) — ABSENT. Product decision needed on what (if anything) ships in mobile v1.
### 2.20 SMS owner (`api/v1/sms/owner/…`) — ABSENT (admin endpoints are for admin panel, ignore).
### 2.21 Information (`api/v1/info/term/`)
Was wired via raw `http` in `terms_conditions.dart` with a **hardcoded real DRF
token** (removed in batch 0; screen now uses DioClient). Root cause: backend
view inherited `IsAuthenticated`, but terms must be readable pre-login — fixed
in backend (`apps/information/views/user_views.py`, `AllowAny`).
### 2.22 `apps.flutter` share/visit-card views (`/markets`, `/products`, `/visit/{id}`, `bank/share/{pk}`) — server-rendered share pages; `business_card`/`bank_card` frontend features are UI shells not linked to them.

## 2.5b Raw-http shadow layer (discovered during batch 0)

Ten files bypass DioClient entirely with `package:http` + `Bearer $token`
(broken against the backend since day one). Each gets migrated to
DioClient + BLoC in its owning batch:

| File | Owning batch |
|---|---|
| `core/widgets/custom_bottom_navbar.dart` | 2 |
| `market/presentation/screens/market_preview_screen.dart`, `market/presentation/widgets/themes_screen.dart` | 2 |
| `product/screens/product_screen.dart` | 3/4 |
| `bookmarks/bookmarks_page.dart` | 4 |
| `cart/presentation/screen/shopping_cart.dart` | 5 |
| `inquiry/presentation/screens/inquiry_requests.dart`, `submit_fee_inquiry.dart` | 8 |
| `bank_card/screens/bank_card_list.dart` | 10 |
| `business_card/presentation/screens/business_part.dart` | 10 |

(`terms_conditions.dart` was the tenth — already migrated in batch 0.)

## 3. Vibe-coded / fake inventory (audit_for_fakes)

**Empty bloc shells** (registered in `locator.dart`, do nothing):
`ChatBloc`, `NotificationBloc`, `ProductBloc`, `ReservationBloc`, `ServiceBloc`,
`BusinessBloc`, `ProfileBloc`, `CustomerBloc`, `ThemeBloc`, `CommentBloc`.

**Features with zero data layer (pure UI):**
chat, notification, product, reservation, service, bookmarks, bank_card,
business_card, customer, panel, profile, store_setting_screens
(vendor reuses create_workspace repo — partially real).

**Mock/hardcoded data:**
- `bookmarks_page.dart:23` — `bookmarks = [MarketModel()]`.
- `add_product_bloc.dart:257` — `shipCost: 2000 // TODO: Update ship cost from backend` (hardcoded business value).
- `store_card.dart`, `vendor_home.dart`, `profile.dart`, `market_preview_screen.dart`, `store_detail_screen.dart`, `store_appbar.dart` — contain mock/placeholder markers (verify per batch).

**Dead UI:** 26 `onPressed/onTap: () {}` or `onPressed: null` sites (buttons that do nothing).

**Fake error handling:** every `catch (e) { return customApiStatus(); }` collapses
all failures (401 vs 500 vs offline) into "no connection"; 4 fully empty
`catch (e) {}` blocks.

**Incomplete flows (TODO-marked):** payment gateway WebView
(`payment_screen.dart:78`), wallet top-up (`wallet_screen.dart:193`), contact
logic + app exit (`profile_menu_widget.dart:34,49`), product-details navigation
(`themes_screen.dart:622`).

**Tests:** only the default `test/widget_test.dart`. No real tests exist.

## 4. Build health

- Flutter 3.44.4 installed locally. `flutter analyze` baseline (2026-07-08):
  **257 issues — 18 errors** (17 in the stale default `test/widget_test.dart`,
  1 real: `wallet_bloc.dart:34` `Object?` → `Map<String, dynamic>` type error),
  rest lints/infos. Production code otherwise compiles.
- `pubspec.yaml` version fixed at `1.0.0+1` (CI must derive from git tag later).

## 5. Backend infra inventory (cleanup batch scope — behavior must not change)

- **6 Dockerfiles:** `Dockerfile`, `.complete`, `.complete.fixed`, `.development`, `.prod`, `.production` — overlapping/dead variants.
- **4 compose files:** `docker-compose.dev.yaml`, `.dev-complete.yaml`, `.prod.yaml`, `.production.yml` — naming inconsistent, duplicates.
- **4+ nginx configs:** root `nginx.conf` + `nginx/nginx.conf`, `nginx/nginx-dev.conf`, `nginx/nginx-main.conf` (+ `config/nginx/`).
- **Hardcoded hosts/IPs** (`5.10.248.32`, `asoud.ir`) in `nginx.conf`, `docker-compose.prod.yaml`, `docker-compose.production.yml`.
- **SECURITY: real SSL private key committed** — `ssl/asoud.key` (+ cert) is tracked in git. Must be removed from the image/compose mounts, gitignored, and the key rotated. History rewrite = owner decision.
- Root of repo cluttered with ~50 generated review/report `.md` files and ad-hoc test scripts (leave unless asked; not runtime-relevant).

## 6. Batch plan & status

| # | Batch | Scope | Status |
|---|-------|-------|--------|
| 0 | Foundation: build health + logging + API core | flutter analyze clean-up, structured logging, DioClient auth fix (C1–C4), error taxonomy in `api_status.dart` | DONE (2026-07-08) |
| 1 | Auth flow end-to-end | AuthSession single-owner token, router auth guard (redirect + refreshListenable), AuthBloc explicit statuses, real OTP submit/resend/countdown, real logout, DRF-exception envelope mapping, analyzer 0 err/0 warn | DONE (2026-07-08) |
| 2a | Owner market: contract fixes | comments endpoint+model fixed & rendered (was hardcoded mock), BookmarkCubit (raw-http bookmarks migrated), themes_screen N+1 raw calls deleted (tag ships in list response), navbar add-to-cart via CartBloc (field `product`, not `product_id`), apiStatus handles bare DRF bodies, 14 dead stub events deleted (workspace + create_workspace), empty CommentBloc deleted, 9 new owner-market service/repo methods (detail/update/contact/location/schedules) | DONE (2026-07-09) |
| 2b | Owner market: edit screens | register editStoreInfo route, wire EditStoreInfoScreen tabs (basic/contact/location) to get/update endpoints, schedules list/update/delete UI | PENDING |
| 3 | Owner: products | product CRUD, detail, ship, themes, discounts (owner) | PENDING |
| 4 | Buyer: browsing | market public list, product search, store/product detail (user side), bookmarks (real) | PENDING |
| 5 | Buyer: cart→payment | cart wiring verify, checkout, discount apply, payment gateway WebView, wallet top-up + tests | PENDING |
| 6 | CI/CD | GitHub Actions: analyze+test on push/PR; tag → signed release APK on GitHub Releases | PENDING |
| 7 | Backend infra cleanup | Dockerfile/compose/nginx consolidation per INFRA_NOTES.md, no behavior change | PENDING |
| 8 | Comments + inquiry completion | comment create/like UI, inquiry list/detail/answers, image upload | PENDING |
| 9 | Notifications + chat | notification list/read, chat rooms/messages (+WS if present) | PENDING |
| 10 | Orders (owner) + secondary | owner order list/verify, advertise self/create+payment, referral, terms screen | PENDING |
| 11 | Reservation module | owner: services/specialists/times/dayoffs; user: browse+reserve+pay (~25 endpoints) | PENDING |
| 12 | Affiliate + analytics | affiliate owner/user flows; owner analytics dashboard (scope: dashboard/sales/products screens) | PENDING |
| 13 | Final audit + release | dead-UI sweep, TODO purge, full regression, v1.0.0 tag | PENDING |

Owner decision 2026-07-08: reservation, analytics, and affiliate are ALL in v1 —
full feature parity with the backend, no reduced scope. Permanent engineering
rules live in `CONVENTIONS.md` (BLoC-only state, no stubs, rewrite-over-patch
for broken foundations).
