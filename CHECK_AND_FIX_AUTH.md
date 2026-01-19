# Проверка и исправление Email провайдера

## Шаг 1: Проверьте текущие переменные окружения контейнера

```bash
docker exec supabase-auth env | grep GOTRUE_EXTERNAL_EMAIL
```

Должно показать:
```
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
```

Если показывает `false` или переменной нет, значит изменения не применились.

## Шаг 2: Проверьте файл docker-compose.yml

```bash
grep -A 2 "GOTRUE_EXTERNAL_EMAIL_ENABLED" /root/docker_data/supabase/docker/docker-compose.yml
```

Должно быть:
```yaml
GOTRUE_EXTERNAL_EMAIL_ENABLED: "true"
```

## Шаг 3: Пересоздайте контейнер (если переменные не применились)

Просто перезапуск не всегда применяет изменения переменных окружения. Нужно пересоздать контейнер:

```bash
cd /root/docker_data/supabase/docker

# Остановить и удалить контейнер
docker compose stop auth
docker compose rm -f auth

# Пересоздать контейнер с новыми настройками
docker compose up -d auth

# Проверить логи
docker compose logs auth | tail -30
```

## Шаг 4: Проверьте переменные после пересоздания

```bash
docker exec supabase-auth env | grep -E "GOTRUE_EXTERNAL_EMAIL|GOTRUE_MAILER_AUTOCONFIRM"
```

Должно показать:
```
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=true
```

## Шаг 5: Проверьте настройки через API

```bash
curl http://localhost:9999/settings | grep -i email
```

Или через браузер откройте:
```
http://176.124.208.227:8000/auth/v1/settings
```

В ответе должно быть `"external.email.enabled": true`
