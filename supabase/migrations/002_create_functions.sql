-- Миграция: Создание функций и триггеров
-- Дата: 2025-01-XX

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Функция для автоматического создания профиля при регистрации пользователя
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

-- Функция для обновления статистики при добавлении тренировки
CREATE OR REPLACE FUNCTION public.update_user_stats_on_workout()
RETURNS TRIGGER AS $$
DECLARE
    old_stats RECORD;
    new_total_workouts INTEGER;
    new_total_exercises INTEGER;
    new_total_minutes INTEGER;
    new_current_streak INTEGER;
    new_max_streak INTEGER;
    new_avg_time DOUBLE PRECISION;
    last_workout_date TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Получить текущую статистику
    SELECT * INTO old_stats
    FROM public.user_stats
    WHERE user_id = NEW.user_id;
    
    -- Если статистика не существует, создать её
    IF NOT FOUND THEN
        INSERT INTO public.user_stats (user_id, updated_at)
        VALUES (NEW.user_id, timezone('utc'::text, now()))
        RETURNING * INTO old_stats;
    END IF;
    
    -- Обновить счетчики
    new_total_workouts := old_stats.total_workouts + CASE WHEN NEW.completed THEN 1 ELSE 0 END;
    new_total_exercises := old_stats.total_exercises + NEW.exercises_count;
    new_total_minutes := old_stats.total_minutes + NEW.duration;
    
    -- Вычислить среднее время тренировки
    IF new_total_workouts > 0 THEN
        new_avg_time := new_total_minutes::DOUBLE PRECISION / new_total_workouts;
    ELSE
        new_avg_time := 0;
    END IF;
    
    -- Проверить streak (серия дней подряд)
    SELECT MAX(date) INTO last_workout_date
    FROM public.workout_history
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND completed = true;
    
    -- Если это первая тренировка или прошло более 2 дней, сбросить streak
    IF last_workout_date IS NULL OR (NEW.date - last_workout_date) > INTERVAL '2 days' THEN
        new_current_streak := CASE WHEN NEW.completed THEN 1 ELSE old_stats.current_streak END;
    ELSE
        -- Увеличить streak если тренировка выполнена
        new_current_streak := CASE 
            WHEN NEW.completed THEN old_stats.current_streak + 1
            ELSE old_stats.current_streak
        END;
    END IF;
    
    -- Обновить максимальный streak
    new_max_streak := GREATEST(old_stats.max_streak, new_current_streak);
    
    -- Обновить статистику
    UPDATE public.user_stats
    SET
        total_workouts = new_total_workouts,
        total_exercises = new_total_exercises,
        total_minutes = new_total_minutes,
        current_streak = new_current_streak,
        max_streak = new_max_streak,
        average_workout_time = new_avg_time,
        updated_at = timezone('utc'::text, now())
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического создания профиля при регистрации
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Триггеры для автоматического обновления updated_at
CREATE TRIGGER set_updated_at_profiles
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_user_preferences
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_workout_plans
    BEFORE UPDATE ON public.workout_plans
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_user_stats
    BEFORE UPDATE ON public.user_stats
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_user_settings
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Триггер для обновления статистики при добавлении тренировки
DROP TRIGGER IF EXISTS on_workout_history_insert ON public.workout_history;
CREATE TRIGGER on_workout_history_insert
    AFTER INSERT ON public.workout_history
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_stats_on_workout();
