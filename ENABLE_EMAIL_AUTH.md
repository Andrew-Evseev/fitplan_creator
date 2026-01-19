# Включение Email аутентификации в Supabase (Self-Hosted)

## Проблема
В логах Supabase видна ошибка: `"error_code": "email_provider_disabled"`. Это означает, что провайдер email-аутентификации отключен в настройках Supabase.

## ⚠️ Важно для Self-Hosted Supabase
В самоподнятом Supabase настройки провайдеров **не доступны через UI**. Их нужно настраивать через **переменные окружения** в `docker-compose.yml`.

## Решение через Docker Compose (Рекомендуется)

### Шаг 1: Подключитесь к серверу
```bash
ssh root@YOUR_SERVER_IP
# Пароль: YOUR_SSH_PASSWORD
```

### Шаг 2: Найдите файл docker-compose.yml
Обычно он находится в одной из этих директорий:
- `/opt/supabase/docker-compose.yml`
- `/root/supabase/docker-compose.yml`
- `/home/supabase/docker-compose.yml`
- Или в директории, где был развернут Supabase

Найдите файл:
```bash
find / -name "docker-compose.yml" -type f 2>/dev/null | grep -i supabase
```

### Шаг 3: Отредактируйте docker-compose.yml
Найдите секцию `auth:` и добавьте/измените следующие переменные окружения:

```yaml
services:
  auth:
    environment:
      # Включить Email провайдер
      GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
      
      # Отключить подтверждение email (для тестирования)
      GOTRUE_MAILER_AUTOCONFIRM: "true"
      
      # URL вашего сайта
      GOTRUE_SITE_URL: "http://YOUR_SERVER_IP:3000"
      
      # Опционально: настройки SMTP (если нужна отправка email)
      # smtp_host: "smtp.example.com"
      # smtp_port: "587"
      # smtp_user: "your-email@example.com"
      # smtp_pass: "your-password"
      # smtp_sender_name: "FitPlan Creator"
      # smtp_admin_email: "noreply@example.com"
```

### Шаг 4: Перезапустите сервис auth
```bash
# Перезапустить только сервис auth
docker-compose restart auth

# Или перезапустить все сервисы
docker-compose restart
```

### Шаг 5: Проверьте логи
```bash
# Проверить логи auth сервиса
docker-compose logs auth | grep -i email

# Или посмотреть все логи
docker-compose logs auth
```

## Альтернативное решение через .env файл

Если используется `.env` файл, добавьте туда:

```env
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=true
GOTRUE_SITE_URL=http://YOUR_SERVER_IP:3000
```

Затем перезапустите:
```bash
docker-compose down
docker-compose up -d
```

## Быстрая проверка через SSH

Если у вас есть доступ к серверу, выполните:

```bash
# Подключитесь к серверу
ssh root@YOUR_SERVER_IP

# Найдите docker-compose.yml
cd /opt/supabase  # или другая директория где Supabase

# Проверьте текущие настройки
grep -A 20 "auth:" docker-compose.yml | grep GOTRUE_EXTERNAL_EMAIL_ENABLED

# Если переменная отсутствует или равна "false", добавьте/измените её
nano docker-compose.yml  # или используйте vi/vim

# После редактирования перезапустите
docker-compose restart auth
```

## Проверка после исправления

После включения email провайдера:
1. Попробуйте зарегистрироваться в приложении
2. Проверьте таблицу `auth.users` - должен появиться новый пользователь
3. Проверьте таблицу `profiles` - должен автоматически создаться профиль (благодаря триггеру)
4. В консоли Flutter должны появиться логи успешной регистрации
