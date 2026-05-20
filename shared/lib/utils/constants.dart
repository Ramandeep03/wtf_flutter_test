class AppConstants {
  // Android emulator → host machine. iOS sim / desktop use http://localhost:3000.
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const streamChatApiKey = String.fromEnvironment(
    'STREAM_CHAT_API_KEY',
    defaultValue: 'YOUR_STREAM_KEY',
  );

  static const joinCallWindowMinutes = 10;
  static const maxNoteLength = 140;
  static const slotDurationMinutes = 30;
  static const slotStartHour = 6; // 06:00
  static const slotEndHour = 22; // 22:00
}
