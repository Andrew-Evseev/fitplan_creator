-- Исправление триггера для создания профиля
-- Выполните этот скрипт, если триггер не работает

-- 1. Удалить старый триггер
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Обновить функцию с обработкой ошибок
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Создать профиль
    INSERT INTO public.profiles (id, name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'Пользователь'),
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO NOTHING;
    
    -- Создать начальную статистику
    INSERT INTO public.user_stats (user_id, updated_at)
    VALUES (NEW.id, timezone('utc'::text, now()))
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Создать начальные настройки
    INSERT INTO public.user_settings (user_id, updated_at)
    VALUES (NEW.id, timezone('utc'::text, now()))
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Логировать ошибку, но не прерывать создание пользователя
        RAISE WARNING 'Ошибка при создании профиля для пользователя %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Создать триггер заново
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 4. Проверить, что триггер создан
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
