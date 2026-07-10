# CHAT_PLAN.md — Real-time chat for Asood (deep plan)

Status: PLAN (no code yet). Owner sign-off requested on the strategy in §5
before implementation. This lands as **batch 9** (after infra cleanup and the
comments/inquiry batch), but the backend fixes in §3 can go earlier since they
are isolated.

## 1. What the backend actually provides

Two transports, both under the chat app.

### 1.1 REST (DRF, Token auth) — works today
Mounted at `api/v1/chat/` via a DRF router (`apps/chat/urls.py`):

- `rooms/` — ModelViewSet (list/create/retrieve/update/delete) + actions:
  - `POST rooms/{id}/add_participant/`, `POST rooms/{id}/remove_participant/`
  - `GET rooms/{id}/participants/`, `GET rooms/{id}/analytics/`
- `messages/` — ModelViewSet + actions:
  - `GET messages/room_messages/?room_id=&page=&page_size=&message_type=`
    → paginated `{results: [...], count, page, ...}`
  - `POST messages/` create — `ChatMessageCreateSerializer`:
    fields `chat_room_id, content, message_type, file_data(reply/base64)`
  - `POST messages/{id}/mark_as_read/`, `POST messages/{id}/edit/`
  - message shape (`ChatMessageSerializer`): `id, content, message_type,
    sender, sender_username, sender_first_name, sender_last_name,
    reply_to_content, reply_to_sender, file_url, file_size_mb, is_edited,
    edited_at, created_at`
- `support/tickets/` — ModelViewSet + `assign/close/resolve/stats`
- `GET chat/search/`, `GET chat/analytics/`

This REST surface is enough for a **fully functional chat** (send, list,
paginate, mark read). It uses the same Token auth every other screen uses, so
it works immediately.

### 1.2 WebSocket (Django Channels) — currently broken
`apps/chat/routing.py`:
- `ws/chat/<str:room_name>/` → `ChatConsumer`
- `ws/support/<str:ticket_id>/` → `SupportConsumer`

Client→server frames: `{type: 'chat_message'|'typing'|'stop_typing'|
'mark_as_read'|'ping', ...}`.
Server→client frames: `{type: 'connection_established'|'chat_message'|
'user_joined'|'user_left'|'typing'|...}`.

## 2. Frontend today

`features/chat` is a shell: an empty `ChatBloc` (`on<ChatEvent>((e,emit){})`),
static `chat_list.dart` / `chat_page.dart` with no data layer. `chat_analytics`
and support tickets have no UI at all. Route `chatList` exists; `chat_page` is
not wired to a room.

## 3. Blocking backend bugs (must fix before WebSocket can ever connect)

Both found by reading `apps/chat/consumers.py` against `routing.py`:

1. **URL kwarg mismatch.** Routing captures `room_name`, but
   `ChatConsumer.connect` reads `self.scope['url_route']['kwargs']['room_id']`
   (consumers.py:41). That raises `KeyError`, caught by the broad `except`,
   which calls `self.close()`. **Every WS connection fails.**
   Fix: rename the routing capture to `<str:room_id>` (least risk), or read
   `room_name` in the consumer. Do the same audit for `SupportConsumer`.

2. **WebSocket auth is session-based, app is token-based.** `config/asgi.py`
   wraps the socket in `AuthMiddlewareStack`, which resolves `scope["user"]`
   from the Django **session cookie**. The mobile app authenticates with a DRF
   **Token** and holds no session cookie, so `scope["user"]` is
   `AnonymousUser` → `connect` closes at the `is_authenticated` check.
   Fix: add a small ASGI middleware that reads a token from the WS query string
   (`?token=<key>`) or the `Authorization` header, resolves the DRF
   `Token` → user, and sets `scope["user"]`. Wrap the chat/support routers with
   it in `asgi.py`.

Until both are fixed, WebSocket is dead. The REST path (§1.1) has neither
problem.

## 4. Target architecture (frontend)

Follow the project's layering and the BLoC-only rule (`CONVENTIONS.md`). One
repository, two interchangeable transports behind it:

```
ChatRemoteDataSource (Dio, Token)        # REST: rooms, room_messages, send, mark_read
ChatSocketDataSource (WebSocketChannel)  # WS: live push (phase B)
        │
        ▼
ChatRepository                            # merges REST history + live stream
        │
        ▼
ChatListCubit         (rooms list)
ChatRoomBloc          (one room: history + pagination + send + live events)
        │
        ▼
chat_list screen / chat_page screen
```

Models: `ChatRoomModel`, `ChatMessageModel` (exact fields from §1.1),
`ChatParticipant`. All parsed from the real serializer output — no invented
fields.

`ChatRoomBloc` events: `LoadRoom`, `LoadMoreMessages`, `SendMessage`,
`MarkRead`, `MessageReceived` (from socket), `TypingChanged`. State carries
`messages`, `hasMore`, `page`, `sending`, `connection` (offline/connecting/
live), `error`. No message state outside the bloc.

## 5. Rollout strategy — DECIDED (2026-07-10)

Owner decisions:
1. **WebSocket-first.** Ship true real-time chat in v1 — not REST+polling.
   So the backend fixes in §3 are prerequisites and land at the start of the
   chat batch.
2. **Support tickets are in v1** — build the customer "contact support" flow
   (`support/tickets/…`) inside the chat batch.
3. **I own the two backend WS fixes** (§3) — do them in this project, tested,
   before the WS client goes live.

Resulting batch-9 order: (a) backend WS fixes + token WS-auth middleware +
verify; (b) `ChatSocketDataSource` + repository (rooms/history via REST,
live via WS); (c) `ChatListCubit` + `ChatRoomBloc` + screens; (d) support
tickets; (e) tests.

### Superseded original recommendation (kept for context): REST-first.

- **Phase A — REST chat (ships value, no backend dependency).**
  DataSource + repository + `ChatListCubit` + `ChatRoomBloc` over the Token
  REST API. History via `room_messages` (paginated, infinite scroll), send via
  `POST messages/`, `mark_as_read`. Near-real-time via light polling of
  `room_messages` while a room is open (e.g. 3–5s), paused when backgrounded.
  Full, usable chat. Tests on the bloc (send/paginate/mark-read/error).

- **Phase B — WebSocket live layer.** After the §3 backend fixes land, add
  `ChatSocketDataSource` (`web_socket_channel` package) connecting to
  `ws/chat/<room_id>/?token=<key>`, emit `MessageReceived`/`TypingChanged`
  into the *same* `ChatRoomBloc`, and drop polling to a fallback. UI and bloc
  API don't change — only the transport. Typing indicators + presence become
  possible here.

Why this order: Phase A is unblocked and low-risk; it delivers a working
feature this milestone. Phase B depends on backend changes and a new auth
middleware, which are riskier and touch production ASGI — better isolated and
verified separately. If the socket work slips, v1 still ships real chat.

**Open product questions for you:**
1. For v1, is **REST + polling** acceptable as the shipping chat, with true
   real-time (WS) as a fast-follow? (Recommended.)
2. Support tickets (`support/tickets/…`) — in the v1 chat batch, or deferred?
   The customer-facing "contact support" flow may want it.
3. Who owns the two backend fixes in §3 — should I make them (they're small and
   isolated) as part of this project, or are they on the backend team?

Once you answer §5, I implement Phase A end-to-end, wire it into the batch
sequence, and schedule the backend fixes + Phase B.
