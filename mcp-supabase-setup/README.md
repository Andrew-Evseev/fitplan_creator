# Настройка MCP сервера для Supabase

Этот набор скриптов помогает настроить MCP (Model Context Protocol) сервер для работы с self-hosted Supabase на timeweb.cloud, чтобы Cursor IDE мог работать с базой данных.

## Архитектура

```
Cursor IDE (локально)
    ↓ SSH Tunnel (опционально)
MCP Server (на сервере :3100)
    ↓ Docker Network
Supabase (Kong API + PostgreSQL)
```

## Предварительные требования

- Доступ по SSH к серверу timeweb.cloud
- Self-hosted Supabase развернутый через Docker
- Node.js 18+ на сервере
- Права root на сервере

## Шаг 1: Включение MCP endpoint в Supabase

MCP endpoint встроен в Supabase, но по умолчанию заблокирован. Нужно разрешить доступ:

### 1.1 Настройка Kong API Gateway

1. Подключитесь к серверу по SSH
2. Перейдите в директорию Supabase
3. Запустите скрипт для определения IP Docker bridge:

```bash
./mcp-supabase-setup/setup-kong.sh
```

4. Отредактируйте файл `./volumes/api/kong.yml`:
   - Найдите секцию с `name: mcp`
   - Закомментируйте или удалите плагин `request-termination`
   - В секции `allow` добавьте IP Docker bridge (например, `172.18.0.1`)

Пример конфигурации Kong:

```yaml
- name: mcp
  routes:
    - name: mcp
      strip_path: false
      paths:
        - /mcp
  plugins:
    - name: ip-restriction
      config:
        allow:
          - 172.18.0.1  # Docker bridge IP
        # request-termination плагин должен быть закомментирован
```

5. Перезапустите Kong:

```bash
docker-compose restart kong
```

## Шаг 2: Установка MCP сервера на сервере

1. Загрузите скрипты на сервер:

```bash
scp -r mcp-supabase-setup/ user@your-server:/opt/
```

2. Подключитесь к серверу по SSH:

```bash
ssh user@your-server
```

3. Запустите скрипт установки:

```bash
cd /opt/mcp-supabase-setup
chmod +x install.sh
sudo ./install.sh
```

4. Настройте переменные окружения:

```bash
cd /opt/mcp-supabase
cp ../mcp-supabase-setup/.env.example .env
nano .env  # или используйте любой редактор
```

Заполните следующие параметры:
- `SUPABASE_URL` - URL Supabase API (для внутреннего доступа: `http://kong:8000`)
- `SUPABASE_DB_URL` - строка подключения к PostgreSQL
- `SUPABASE_SERVICE_ROLE_KEY` - Service Role Key из Supabase Dashboard
- `MCP_PORT` - порт для MCP сервера (по умолчанию 3100)
- `MCP_READ_ONLY` - `false` для полного доступа, `true` только для чтения

5. Установите systemd service:

```bash
sudo cp ../mcp-supabase-setup/mcp-supabase.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mcp-supabase
sudo systemctl start mcp-supabase
sudo systemctl status mcp-supabase
```

## Шаг 3: Настройка доступа

### Вариант A: Прямое подключение (не рекомендуется для продакшена)

Если MCP сервер доступен напрямую через интернет:

1. Откройте порт в firewall:

```bash
sudo ufw allow 3100/tcp
```

2. В конфигурации Cursor используйте прямой URL:

```json
{
  "mcpServers": {
    "supabase": {
      "url": "http://your-server.timeweb.cloud:3100"
    }
  }
}
```

### Вариант B: SSH туннель (рекомендуется)

1. Настройте SSH туннель локально:

Отредактируйте `mcp-supabase-setup/ssh-tunnel.sh` и укажите:
- `REMOTE_HOST` - адрес вашего сервера
- `REMOTE_USER` - пользователь для SSH
- `REMOTE_PORT` - порт MCP сервера (3100)
- `LOCAL_PORT` - локальный порт (3100)

2. Запустите туннель:

```bash
chmod +x mcp-supabase-setup/ssh-tunnel.sh
./mcp-supabase-setup/ssh-tunnel.sh
```

3. Оставьте терминал открытым (туннель работает пока терминал открыт)

## Шаг 4: Конфигурация Cursor

### 4.1 Найти конфигурационный файл Cursor

В Windows конфигурация MCP обычно находится в:
- `%APPDATA%\Cursor\User\globalStorage\mcp.json`
- Или через настройки Cursor: Settings -> Features -> MCP Servers

### 4.2 Настройка через командную строку (локальный MCP сервер)

Если используете SSH туннель или запускаете MCP локально, используйте конфигурацию через `command`:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase-community/mcp-server-supabase@latest",
        "--url=http://localhost:3100",
        "--db-url=postgresql://postgres:password@localhost:5432/postgres",
        "--service-role-key=your_service_role_key"
      ]
    }
  }
}
```

### 4.3 Настройка через HTTP (если MCP доступен напрямую)

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "http://localhost:3100",
      "headers": {
        "Authorization": "Bearer your_token_if_needed"
      }
    }
  }
}
```

## Проверка работы

1. Проверьте, что MCP сервер запущен:

```bash
# На сервере
sudo systemctl status mcp-supabase
curl http://localhost:3100/health  # если есть health endpoint
```

2. Проверьте подключение через SSH туннель (если используете):

```bash
# Локально
curl http://localhost:3100
```

3. Перезапустите Cursor и проверьте, что MCP сервер подключен в настройках

4. Попробуйте дать Cursor задачу типа:
   - "Покажи список таблиц в базе данных"
   - "Создай таблицу users с полями id, email, name"
   - "Выполни SELECT запрос к таблице..."

## Устранение неполадок

### MCP сервер не запускается

1. Проверьте логи:

```bash
sudo journalctl -u mcp-supabase -f
```

2. Проверьте переменные окружения:

```bash
sudo systemctl show mcp-supabase --property=Environment
```

3. Проверьте подключение к Supabase:

```bash
curl http://kong:8000/health
```

### Cursor не может подключиться

1. Убедитесь, что SSH туннель активен (если используете)
2. Проверьте, что порт не заблокирован firewall
3. Проверьте логи Cursor на наличие ошибок подключения

### Ошибки доступа к базе данных

1. Убедитесь, что `SUPABASE_DB_URL` правильный
2. Проверьте, что контейнеры Supabase в той же Docker network
3. Убедитесь, что Service Role Key правильный

## Безопасность

- **Не открывайте** MCP порт в интернет без аутентификации
- Используйте SSH туннель для безопасного доступа
- Используйте `MCP_READ_ONLY=true` для ограничения прав доступа
- Регулярно обновляйте MCP сервер и Supabase
- Храните секреты (Service Role Key) в защищенном месте

## Полезные ссылки

- [Документация Supabase MCP](https://supabase.com/docs/guides/self-hosting/enable-mcp)
- [Community MCP Server для Supabase](https://github.com/supabase-community/supabase-mcp)
- [Документация MCP Protocol](https://modelcontextprotocol.io/)
