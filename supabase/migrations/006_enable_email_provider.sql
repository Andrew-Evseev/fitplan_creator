-- Включение Email провайдера через SQL
-- Выполните этот скрипт в SQL Editor Supabase

-- Проверка текущей конфигурации
SELECT 
    key,
    value
FROM auth.config
WHERE key = 'EXTERNAL_EMAIL_ENABLED' OR key LIKE '%email%';

-- Включение Email провайдера
-- Вариант 1: Если используется таблица auth.config
UPDATE auth.config
SET value = 'true'
WHERE key = 'EXTERNAL_EMAIL_ENABLED';

-- Вариант 2: Если используется таблица auth.settings
UPDATE auth.settings
SET value = 'true'
WHERE key = 'EXTERNAL_EMAIL_ENABLED';

-- Вариант 3: Прямое обновление через функцию (для самоподнятого Supabase)
-- Включить email провайдер
INSERT INTO auth.config (key, value)
VALUES ('EXTERNAL_EMAIL_ENABLED', 'true')
ON CONFLICT (key) DO UPDATE SET value = 'true';

-- Также включим подтверждение email (можно отключить позже для тестирования)
INSERT INTO auth.config (key, value)
VALUES ('MAILER_AUTOCONFIRM', 'true')
ON CONFLICT (key) DO UPDATE SET value = 'true';

-- Проверка результата
SELECT 
    key,
    value
FROM auth.config
WHERE key IN ('EXTERNAL_EMAIL_ENABLED', 'MAILER_AUTOCONFIRM');

-- Альтернативный способ через обновление настроек проекта
-- Если предыдущие способы не работают, попробуйте:
UPDATE auth.config
SET value = jsonb_set(
    COALESCE(value::jsonb, '{}'::jsonb),
    '{enabled}',
    'true'::jsonb
)
WHERE key = 'EXTERNAL_EMAIL_ENABLED';
