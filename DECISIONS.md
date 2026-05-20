# Architecture Decision Records

## ADR #1 — Backend-first (Node.js)
**Decision:** All Firebase access goes through a Node.js backend using Firebase Admin SDK. Flutter apps never embed `firebase_auth` or `cloud_firestore`.
**Why:**
- Secrets (service account, 100ms, Stream) live in one place.
- Business rules and Firestore writes are validated server-side.
- Two clients (guru + trainer) share one source of truth without duplicating SDK setup.
**Consequence:** Slightly higher round-trip latency vs. direct SDK use, accepted in exchange for security + a single auth boundary.

## ADR #2 — Stream Chat for messaging
**Decision:** Use Stream Chat (`stream_chat_flutter` on client, server SDK on backend) for 1:1 and group chat.
**Why:** Built-in presence, typing, attachments, moderation. Faster than rolling chat over Firestore.
**Consequence:** Backend mints Stream user tokens at `/stream_token`. Stream publishable key ships to Flutter; secret stays server-side.

## ADR #3 — 100ms for audio/video
**Decision:** Use 100ms (`hmssdk_flutter`) for calls. Room creation and auth-token minting happen on backend (`/rooms`, `/hms_token`).
**Why:** Mature SDK, prebuilt UI, server-side template control.
**Consequence:** Backend owns 100ms app access key + secret. Tokens are short-lived and scoped per room/user.

## ADR #4 — BLoC for state management
**Decision:** Use `flutter_bloc` (BLoC + Cubit) across both apps. Feature folders follow `data/ domain/ presentation/bloc/`.
**Why:** Predictable, testable (`bloc_test`), team familiarity. Keeps presentation thin.
**Consequence:** Every async UI flow goes through a BLoC; no `setState` for network-driven UI.

## ADR #5 — `api_state` for request states
**Decision:** Use the `api_state` package (v1.0.0+) for BLoC/Cubit states that wrap an HTTP call.
**Why:** Sealed classes + exhaustive `switch` give compile-time guarantees that every state is handled in the UI. No bespoke `status + data + errorMessage` triples per feature.
**Pattern:**
```dart
class UsersCubit extends Cubit<ApiStatus<List<User>>> {
  UsersCubit(this._repo) : super(const ApiInitial());
  final UserRepository _repo;

  Future<void> load() async {
    emit(const ApiLoading());
    emit(await ApiStatus.guard(
      () => _repo.getUsers(),
      onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
    ));
  }
}
```
**Note:** Original P01 brief specified an enum `loading|completed|error` with separate `data` and `errorMessage` fields. The real `api_state` package uses **sealed classes** instead; we adopt the package's idiomatic shape and require all feature BLoCs to use it.
**Consequence:** UI consumes states via `switch (state) { ApiLoading() => ..., ApiSuccess(:final data) => ..., ApiFailure(:final message) => ... }`.

## ADR #6 — `flutter_local_notifications` for reminders
**Decision:** Use `flutter_local_notifications` (+ `timezone` / `flutter_timezone`) for session reminders and call alerts in P01.
**Why:** No FCM infra needed yet. Reminders are derived from data already pulled from backend (`session_logs`, `call_requests`).
**Consequence:** No background push delivery to closed apps — accepted for P01. FCM can be added later behind the same notification feature.
