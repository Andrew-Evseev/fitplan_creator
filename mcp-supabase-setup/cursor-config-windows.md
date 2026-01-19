# Настройка Cursor для работы с MCP сервером Supabase (Windows)

## Нахождение конфигурационного файла Cursor

В Windows конфигурация MCP серверов может находиться в следующих местах:

1. **Через настройки Cursor (рекомендуется):**
   - Откройте Cursor
   - Перейдите в `File` -> `Preferences` -> `Settings`
   - Найдите секцию "MCP Servers" или "Model Context Protocol"
   - Добавьте конфигурацию сервера через интерфейс

2. **Через файл конфигурации:**
   - Путь: `%APPDATA%\Cursor\User\settings.json`
   - Или: `%APPDATA%\Cursor\User\globalStorage\mcp.json`
   - Или: `C:\Users\<YourUsername>\AppData\Roaming\Cursor\User\settings.json`

## Вариант 1: Подключение через SSH туннель (рекомендуется)

### Шаг 1: Настройка SSH туннеля

1. Установите Git Bash или WSL, если еще не установлены (для работы с SSH)

2. Создайте файл `start-ssh-tunnel.bat`:

```batch
@echo off
echo Starting SSH tunnel to MCP server...
ssh -N -L 3100:localhost:3100 root@your-server.timeweb.cloud
pause
```

3. Замените `your-server.timeweb.cloud` на адрес вашего сервера

4. Запустите этот файл перед использованием Cursor (оставьте окно открытым)

### Шаг 2: Конфигурация Cursor

Если Cursor поддерживает MCP через командную строку, добавьте в настройки:

**Через интерфейс настроек:**
- Откройте Settings -> MCP Servers
- Добавьте новый сервер с именем "supabase"
- Выберите тип: "Command"
- Команда: `npx`
- Аргументы: 
  ```
  -y
  @supabase-community/mcp-server-supabase@latest
  --url=http://localhost:3100
  ```

**Или через JSON (если используется файл конфигурации):**

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase-community/mcp-server-supabase@latest",
        "--url=http://localhost:3100",
        "--db-url=postgresql://postgres:your_password@localhost:5432/postgres",
        "--service-role-key=your_service_role_key_here"
      ]
    }
  }
}
```

## Вариант 2: Локальный запуск MCP сервера (если Node.js установлен локально)

Если вы хотите запускать MCP сервер локально на Windows:

1. Установите Node.js 18+ с [nodejs.org](https://nodejs.org/)

2. Создайте папку для проекта, например `C:\mcp-supabase`

3. Создайте файл `package.json`:

```json
{
  "name": "mcp-supabase-local",
  "version": "1.0.0",
  "dependencies": {
    "@supabase-community/mcp-server-supabase": "latest"
  },
  "scripts": {
    "start": "npx @supabase-community/mcp-server-supabase@latest --url=http://your-server:3100"
  }
}
```

4. Создайте файл `.env`:

```
SUPABASE_URL=http://your-server:3100
SUPABASE_DB_URL=postgresql://postgres:password@your-server:5432/postgres
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

5. Настройте Cursor для использования локального сервера

## Вариант 3: Прямое подключение (если порт открыт)

Если MCP сервер доступен напрямую через интернет (не рекомендуется без аутентификации):

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "http://your-server.timeweb.cloud:3100"
    }
  }
}
```

## Проверка подключения

1. Перезапустите Cursor после изменения конфигурации

2. Откройте чат/командную панель в Cursor

3. Попробуйте запрос:
   - "Покажи список таблиц в базе данных Supabase"
   - "Какие таблицы есть в моей базе данных?"
   - "Создай таблицу test с полями id и name"

4. Если MCP сервер настроен правильно, Cursor должен иметь доступ к базе данных

## Устранение неполадок

### Cursor не подключается к MCP серверу

1. **Проверьте SSH туннель:**
   - Убедитесь, что SSH туннель запущен и работает
   - Проверьте подключение: `curl http://localhost:3100` в PowerShell

2. **Проверьте логи:**
   - Откройте Developer Tools в Cursor (Help -> Toggle Developer Tools)
   - Проверьте консоль на наличие ошибок

3. **Проверьте формат конфигурации:**
   - Убедитесь, что JSON валиден
   - Проверьте правильность путей и URL

### Ошибки подключения к базе данных

1. **Проверьте параметры подключения:**
   - Убедитесь, что `SUPABASE_DB_URL` правильный
   - Проверьте, что Service Role Key верный
   - Убедитесь, что Supabase доступен с сервера MCP

2. **Проверьте сеть:**
   - Убедитесь, что сервер MCP может подключиться к Supabase
   - Проверьте firewall правила

## Полезные ссылки

- [Документация Cursor MCP](https://docs.cursor.com/)
- [Community MCP Server для Supabase](https://github.com/supabase-community/supabase-mcp)
- [Документация MCP Protocol](https://modelcontextprotocol.io/)
