# Миграции базы данных Supabase

## Применение миграций

1. Откройте Supabase Dashboard: http://176.124.208.227:8000
2. Войдите с учетными данными:
   - Логин: supabase
   - Пароль: Ofsaid13
3. Перейдите в раздел **SQL Editor**
4. Откройте файл `000_apply_all_migrations.sql`
5. Скопируйте весь SQL код и вставьте в редактор
6. Нажмите **Run** для выполнения миграции

## Структура миграций

- `000_apply_all_migrations.sql` - Полная миграция (использовать этот файл)
- `001_create_tables.sql` - Только создание таблиц
- `002_create_functions.sql` - Только функции и триггеры
- `003_create_rls_policies.sql` - Только RLS политики

## Созданные таблицы

1. **profiles** - Профили пользователей
2. **user_preferences** - Предпочтения из анкеты
3. **workout_plans** - Планы тренировок
4. **workout_history** - История тренировок
5. **user_stats** - Статистика пользователей
6. **user_settings** - Настройки пользователей

## Автоматические функции

- **handle_new_user()** - Автоматически создает профиль, статистику и настройки при регистрации
- **handle_updated_at()** - Автоматически обновляет поле updated_at
- **update_user_stats_on_workout()** - Автоматически обновляет статистику при добавлении тренировки

## Проверка после миграции

Выполните следующие запросы для проверки:

```sql
-- Проверить созданные таблицы
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('profiles', 'user_preferences', 'workout_plans', 'workout_history', 'user_stats', 'user_settings');

-- Проверить функции
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('handle_new_user', 'handle_updated_at', 'update_user_stats_on_workout');

-- Проверить RLS политики
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```
