# Voya

Flutter travel planning app backed by Supabase.

## Supabase configuration

The Supabase project URL is configured in `lib/main.dart`. Supply the public
anon/publishable key at runtime; do not commit it:

```sh
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key
```

Enable anonymous sign-ins in Supabase Authentication if you want to use the
development “Create test draft” action. The `trips` table must have Realtime
enabled for live trip streams.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
