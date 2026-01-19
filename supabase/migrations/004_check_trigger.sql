-- Скрипт для проверки триггера и функции создания профиля
-- Выполните в SQL Editor для диагностики

-- 1. Проверить существование функции
SELECT 
    routine_name, 
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'handle_new_user' 
  AND routine_schema = 'public';

-- 2. Проверить существование триггера
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement,
    action_timing,
    action_orientation
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 3. Проверить последних созданных пользователей
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Проверить профили для этих пользователей
SELECT 
    p.id,
    p.name,
    p.created_at,
    u.email
FROM public.profiles p
RIGHT JOIN auth.users u ON p.id = u.id
ORDER BY u.created_at DESC
LIMIT 5;

-- 5. Если триггер не работает, создать профиль вручную для последнего пользователя
-- (РАСКОММЕНТИРУЙТЕ И ЗАМЕНИТЕ USER_ID на реальный ID из шага 3)
/*
DO $$
DECLARE
    latest_user_id UUID;
BEGIN
    -- Получить ID последнего созданного пользователя
    SELECT id INTO latest_user_id
    FROM auth.users
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Создать профиль, если его нет
    INSERT INTO public.profiles (id, name, created_at, updated_at)
    SELECT 
        latest_user_id,
        COALESCE((SELECT raw_user_meta_data->>'name' FROM auth.users WHERE id = latest_user_id), 'Пользователь'),
        now(),
        now()
    WHERE NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = latest_user_id
    );
    
    -- Создать статистику, если её нет
    INSERT INTO public.user_stats (user_id, updated_at)
    SELECT latest_user_id, now()
    WHERE NOT EXISTS (
        SELECT 1 FROM public.user_stats WHERE user_id = latest_user_id
    );
    
    -- Создать настройки, если их нет
    INSERT INTO public.user_settings (user_id, updated_at)
    SELECT latest_user_id, now()
    WHERE NOT EXISTS (
        SELECT 1 FROM public.user_settings WHERE user_id = latest_user_id
    );
    
    RAISE NOTICE 'Профиль создан для пользователя: %', latest_user_id;
END $$;
*/
