import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';

import 'in_memory_token_storage.dart';

void main() {
  test('hydrate loads persisted token and marks session hydrated', () async {
    final session = AuthSession(InMemoryTokenStorage('abc'));

    expect(session.isHydrated, isFalse);
    await session.hydrate();

    expect(session.isHydrated, isTrue);
    expect(session.isAuthenticated, isTrue);
    expect(session.token, 'abc');
  });

  test('hydrate with empty storage stays anonymous', () async {
    final session = AuthSession(InMemoryTokenStorage());

    await session.hydrate();

    expect(session.isAuthenticated, isFalse);
    expect(session.token, isNull);
  });

  test('setToken persists and notifies listeners', () async {
    final storage = InMemoryTokenStorage();
    final session = AuthSession(storage);
    var notified = 0;
    session.addListener(() => notified++);

    await session.setToken('tok');

    expect(storage.value, 'tok');
    expect(session.isAuthenticated, isTrue);
    expect(notified, 1);
  });

  test('clear wipes storage and notifies once, then becomes a no-op', () async {
    final storage = InMemoryTokenStorage('tok');
    final session = AuthSession(storage);
    await session.hydrate();
    var notified = 0;
    session.addListener(() => notified++);

    await session.clear();
    await session.clear();

    expect(storage.value, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(notified, 1);
  });
}
