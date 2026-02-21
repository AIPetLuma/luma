# Phase G Manual Validation Checklist

## 1. No Firebase / No Supabase configured
- Run app without `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and Firebase config files.
- Expected:
  - App starts normally.
  - Onboarding, chat, and settings all function.
  - No crash when entering settings or chat.

## 2. Supabase anonymous auth + backup
- Configure:
  - `--dart-define SUPABASE_URL=...`
  - `--dart-define SUPABASE_ANON_KEY=...`
- Create a pet, open Settings, tap cloud backup.
- Expected:
  - Backup success status appears.
  - `pet_backups` has row with current `owner_id` and pet data.
  - `listBackups` returns only this user rows.

## 3. RLS isolation
- Use two different anonymous users (A and B).
- A writes one backup and one experiment event.
- B queries `pet_backups`, `fcm_tokens`, `experiment_events`.
- Expected:
  - B cannot read/write A rows.
  - RLS policies enforce `auth.uid() = owner_id`.

## 4. Retention server-side trigger
- Insert `signup_completed` at T0.
- Insert `session_started` at:
  - `T0 + 25h` => expect `user_returned_d1`
  - `T0 + 7d + 1m` => expect `user_returned_d7`
  - `T0 + 21d + 1m` => expect `user_returned_d21`
- Repeat `session_started` in same windows.
- Expected:
  - D1/D7/D21 are each inserted once (deduped).

## 5. Firebase + FCM token upsert
- Add Firebase platform config files.
- Launch app, grant notification permission.
- Enter app with pet loaded.
- Expected:
  - FCM token is fetched.
  - `fcm_tokens` row is upserted with owner/pet/platform/locale.

## 6. Foreground push path
- Invoke `supabase/functions/send_push` with a user-owned `token` or `pet_id`.
- Expected:
  - Function returns success payload.
  - App receives foreground message and shows local notification.

## 7. Topic push permission
- Try topic push as normal authenticated user.
- Expected: blocked (403).
- Try topic push with service-role authorization.
- Expected: allowed.

## 8. Mixed push mode regression
- Keep app idle/background long enough for WorkManager local reach-out notifications.
- Also send one remote push from Edge Function.
- Expected:
  - Existing local notification behavior remains.
  - Remote push is additive (no regression).
