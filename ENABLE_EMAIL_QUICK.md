# Быстрое включение Email провайдера

## Через SSH (Самый быстрый способ)

```bash
# 1. Подключитесь к серверу
ssh root@YOUR_SERVER_IP
# Пароль: YOUR_SSH_PASSWORD

# 2. Найдите директорию Supabase
cd /opt/supabase  # или другая директория

# 3. Отредактируйте docker-compose.yml
nano docker-compose.yml

# 4. Найдите секцию auth: и добавьте/измените:
#    GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
#    GOTRUE_MAILER_AUTOCONFIRM: "true"

# 5. Сохраните (Ctrl+O, Enter, Ctrl+X)

# 6. Перезапустите auth сервис
docker-compose restart auth

# 7. Проверьте логи
docker-compose logs -f auth
```

## Что именно нужно добавить в docker-compose.yml

В секции `services.auth.environment` добавьте:

```yaml
GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
GOTRUE_MAILER_AUTOCONFIRM: "true"
GOTRUE_SITE_URL: "http://YOUR_SERVER_IP:3000"
```

## Проверка после изменений

1. Попробуйте зарегистрироваться в приложении
2. Проверьте логи: `docker-compose logs auth | grep signup`
3. Ошибка `email_provider_disabled` должна исчезнуть
