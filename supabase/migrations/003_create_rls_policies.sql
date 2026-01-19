-- Миграция: Настройка Row Level Security (RLS) политик
-- Дата: 2025-01-XX

-- Включить RLS для всех таблиц
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- ========== PROFILES ==========

-- Пользователи могут читать свои профили
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Пользователи могут обновлять свои профили
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Пользователи могут вставлять свои профили (на случай если триггер не сработает)
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ========== USER_PREFERENCES ==========

-- Пользователи могут читать свои предпочтения
CREATE POLICY "Users can view own preferences"
    ON public.user_preferences
    FOR SELECT
    USING (auth.uid() = user_id);

-- Пользователи могут создавать свои предпочтения
CREATE POLICY "Users can create own preferences"
    ON public.user_preferences
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять свои предпочтения
CREATE POLICY "Users can update own preferences"
    ON public.user_preferences
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Пользователи могут удалять свои предпочтения
CREATE POLICY "Users can delete own preferences"
    ON public.user_preferences
    FOR DELETE
    USING (auth.uid() = user_id);

-- ========== WORKOUT_PLANS ==========

-- Пользователи могут читать свои планы тренировок
CREATE POLICY "Users can view own workout plans"
    ON public.workout_plans
    FOR SELECT
    USING (auth.uid() = user_id);

-- Пользователи могут создавать свои планы тренировок
CREATE POLICY "Users can create own workout plans"
    ON public.workout_plans
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять свои планы тренировок
CREATE POLICY "Users can update own workout plans"
    ON public.workout_plans
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Пользователи могут удалять свои планы тренировок
CREATE POLICY "Users can delete own workout plans"
    ON public.workout_plans
    FOR DELETE
    USING (auth.uid() = user_id);

-- ========== WORKOUT_HISTORY ==========

-- Пользователи могут читать свою историю тренировок
CREATE POLICY "Users can view own workout history"
    ON public.workout_history
    FOR SELECT
    USING (auth.uid() = user_id);

-- Пользователи могут создавать записи в своей истории тренировок
CREATE POLICY "Users can create own workout history"
    ON public.workout_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять свои записи в истории тренировок
CREATE POLICY "Users can update own workout history"
    ON public.workout_history
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Пользователи могут удалять свои записи из истории тренировок
CREATE POLICY "Users can delete own workout history"
    ON public.workout_history
    FOR DELETE
    USING (auth.uid() = user_id);

-- ========== USER_STATS ==========

-- Пользователи могут читать свою статистику
CREATE POLICY "Users can view own stats"
    ON public.user_stats
    FOR SELECT
    USING (auth.uid() = user_id);

-- Пользователи могут создавать свою статистику (на случай если триггер не сработает)
CREATE POLICY "Users can create own stats"
    ON public.user_stats
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять свою статистику
CREATE POLICY "Users can update own stats"
    ON public.user_stats
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ========== USER_SETTINGS ==========

-- Пользователи могут читать свои настройки
CREATE POLICY "Users can view own settings"
    ON public.user_settings
    FOR SELECT
    USING (auth.uid() = user_id);

-- Пользователи могут создавать свои настройки (на случай если триггер не сработает)
CREATE POLICY "Users can create own settings"
    ON public.user_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Пользователи могут обновлять свои настройки
CREATE POLICY "Users can update own settings"
    ON public.user_settings
    FOR UPDATE
    USING (auth.uid() = user_id);
