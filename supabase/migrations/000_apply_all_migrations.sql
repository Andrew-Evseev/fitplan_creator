-- Полная миграция для FitPlan Creator
-- Применять через SQL Editor в Supabase Dashboard
-- Порядок применения: выполнить весь файл последовательно

-- ========================================
-- 1. СОЗДАНИЕ ТАБЛИЦ
-- ========================================

-- Расширенный профиль пользователя
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Предпочтения пользователя из анкеты
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    preferences_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)
);

-- Планы тренировок
CREATE TABLE IF NOT EXISTS public.workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    training_system TEXT,
    plan_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- История тренировок
CREATE TABLE IF NOT EXISTS public.workout_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES public.workout_plans(id) ON DELETE SET NULL,
    plan_name TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    duration INTEGER NOT NULL DEFAULT 0,
    exercises_count INTEGER NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Статистика пользователя
CREATE TABLE IF NOT EXISTS public.user_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_workouts INTEGER NOT NULL DEFAULT 0,
    total_exercises INTEGER NOT NULL DEFAULT 0,
    total_minutes INTEGER NOT NULL DEFAULT 0,
    current_streak INTEGER NOT NULL DEFAULT 0,
    max_streak INTEGER NOT NULL DEFAULT 0,
    muscle_group_distribution JSONB NOT NULL DEFAULT '{}'::jsonb,
    average_workout_time DOUBLE PRECISION NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)
);

-- Настройки пользователя
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    dark_mode BOOLEAN NOT NULL DEFAULT false,
    language TEXT NOT NULL DEFAULT 'ru',
    units TEXT NOT NULL DEFAULT 'metric',
    auto_save BOOLEAN NOT NULL DEFAULT true,
    show_tutorials BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)
);

-- Индексы
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user_id ON public.workout_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_history_user_id ON public.workout_history(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_history_date ON public.workout_history(date DESC);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON public.user_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);

-- ========================================
-- 2. СОЗДАНИЕ ФУНКЦИЙ
-- ========================================

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Функция для автоматического создания профиля при регистрации
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
    SELECT * INTO old_stats
    FROM public.user_stats
    WHERE user_id = NEW.user_id;
    
    IF NOT FOUND THEN
        INSERT INTO public.user_stats (user_id, updated_at)
        VALUES (NEW.user_id, timezone('utc'::text, now()))
        RETURNING * INTO old_stats;
    END IF;
    
    new_total_workouts := old_stats.total_workouts + CASE WHEN NEW.completed THEN 1 ELSE 0 END;
    new_total_exercises := old_stats.total_exercises + NEW.exercises_count;
    new_total_minutes := old_stats.total_minutes + NEW.duration;
    
    IF new_total_workouts > 0 THEN
        new_avg_time := new_total_minutes::DOUBLE PRECISION / new_total_workouts;
    ELSE
        new_avg_time := 0;
    END IF;
    
    SELECT MAX(date) INTO last_workout_date
    FROM public.workout_history
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND completed = true;
    
    IF last_workout_date IS NULL OR (NEW.date - last_workout_date) > INTERVAL '2 days' THEN
        new_current_streak := CASE WHEN NEW.completed THEN 1 ELSE old_stats.current_streak END;
    ELSE
        new_current_streak := CASE 
            WHEN NEW.completed THEN old_stats.current_streak + 1
            ELSE old_stats.current_streak
        END;
    END IF;
    
    new_max_streak := GREATEST(old_stats.max_streak, new_current_streak);
    
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

-- ========================================
-- 3. СОЗДАНИЕ ТРИГГЕРОВ
-- ========================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

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

DROP TRIGGER IF EXISTS on_workout_history_insert ON public.workout_history;
CREATE TRIGGER on_workout_history_insert
    AFTER INSERT ON public.workout_history
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_stats_on_workout();

-- ========================================
-- 4. НАСТРОЙКА RLS ПОЛИТИК
-- ========================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- PROFILES policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- USER_PREFERENCES policies
DROP POLICY IF EXISTS "Users can view own preferences" ON public.user_preferences;
CREATE POLICY "Users can view own preferences" ON public.user_preferences FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can create own preferences" ON public.user_preferences;
CREATE POLICY "Users can create own preferences" ON public.user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own preferences" ON public.user_preferences;
CREATE POLICY "Users can update own preferences" ON public.user_preferences FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own preferences" ON public.user_preferences;
CREATE POLICY "Users can delete own preferences" ON public.user_preferences FOR DELETE USING (auth.uid() = user_id);

-- WORKOUT_PLANS policies
DROP POLICY IF EXISTS "Users can view own workout plans" ON public.workout_plans;
CREATE POLICY "Users can view own workout plans" ON public.workout_plans FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can create own workout plans" ON public.workout_plans;
CREATE POLICY "Users can create own workout plans" ON public.workout_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own workout plans" ON public.workout_plans;
CREATE POLICY "Users can update own workout plans" ON public.workout_plans FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own workout plans" ON public.workout_plans;
CREATE POLICY "Users can delete own workout plans" ON public.workout_plans FOR DELETE USING (auth.uid() = user_id);

-- WORKOUT_HISTORY policies
DROP POLICY IF EXISTS "Users can view own workout history" ON public.workout_history;
CREATE POLICY "Users can view own workout history" ON public.workout_history FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can create own workout history" ON public.workout_history;
CREATE POLICY "Users can create own workout history" ON public.workout_history FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own workout history" ON public.workout_history;
CREATE POLICY "Users can update own workout history" ON public.workout_history FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own workout history" ON public.workout_history;
CREATE POLICY "Users can delete own workout history" ON public.workout_history FOR DELETE USING (auth.uid() = user_id);

-- USER_STATS policies
DROP POLICY IF EXISTS "Users can view own stats" ON public.user_stats;
CREATE POLICY "Users can view own stats" ON public.user_stats FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can create own stats" ON public.user_stats;
CREATE POLICY "Users can create own stats" ON public.user_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
CREATE POLICY "Users can update own stats" ON public.user_stats FOR UPDATE USING (auth.uid() = user_id);

-- USER_SETTINGS policies
DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
CREATE POLICY "Users can view own settings" ON public.user_settings FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can create own settings" ON public.user_settings;
CREATE POLICY "Users can create own settings" ON public.user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING (auth.uid() = user_id);
