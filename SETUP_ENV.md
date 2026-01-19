# Настройка переменных окружения

## Для локальной разработки:

### Вариант 1: Использование --dart-define (рекомендуется для Flutter web)

Создайте файл `launch.json` в `.vscode/` или запускайте через командную строку:

```bash
flutter run --dart-define=SUPABASE_URL=http://your-server:8000 --dart-define=SUPABASE_ANON_KEY=your_key
```

### Вариант 2: Использование flutter_dotenv (для мобильных платформ)

1. Добавьте зависимость в `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Создайте файл `.env` в корне проекта:
```env
SUPABASE_URL=http://your-server:8000
SUPABASE_ANON_KEY=your_key
```

3. Добавьте `.env` в `assets` в `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

4. Загрузите переменные в `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ...
}
```

5. Используйте в коде:
```dart
final url = dotenv.env['SUPABASE_URL']!;
final key = dotenv.env['SUPABASE_ANON_KEY']!;
```

## Для продакшена:

Используйте переменные окружения вашей платформы:
- **Vercel**: Settings → Environment Variables
- **Netlify**: Site settings → Environment variables
- **Firebase Hosting**: Firebase Console → Functions → Config
