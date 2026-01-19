# Быстрый старт: Настройка MCP сервера для Supabase

Краткое руководство по настройке MCP сервера за 5 минут.

## На сервере (timeweb.cloud)

### Шаг 1: Загрузить скрипты на сервер

```bash
scp -r mcp-supabase-setup/ root@your-server:/opt/
```

### Шаг 2: Подключиться к серверу

```bash
ssh root@your-server
```

### Шаг 3: Запустить автоматическую настройку

```bash
cd /opt/mcp-supabase-setup
chmod +x *.sh
sudo ./setup-complete.sh
```

Скрипт автоматически:
- Установит Node.js (если нужно)
- Установит MCP сервер
- Создаст файл конфигурации .env
- Установит systemd service

### Шаг 4: Отредактировать конфигурацию

```bash
nano /opt/mcp-supabase/.env
```

Заполните:
- `SUPABASE_URL` - обычно `http://kong:8000` для внутреннего доступа
- `SUPABASE_DB_URL` - строка подключения к PostgreSQL
- `SUPABASE_SERVICE_ROLE_KEY` - Service Role Key из Supabase

### Шаг 5: Запустить MCP сервер

```bash
systemctl enable --now mcp-supabase
systemctl status mcp-supabase
```

### Шаг 6: Настроить Kong (опционально)

Если нужно включить MCP endpoint в Supabase:

```bash
cd /path/to/supabase  # директория с docker-compose.yml
bash /opt/mcp-supabase-setup/setup-kong.sh
# Затем отредактируйте ./volumes/api/kong.yml вручную
docker-compose restart kong
```

## На локальном компьютере (Windows)

### Вариант 1: SSH туннель (рекомендуется)

1. Отредактируйте `mcp-supabase-setup/start-ssh-tunnel.bat`:
   - Замените `your-server.timeweb.cloud` на адрес вашего сервера
   - Замените `root` на вашего пользователя (если нужно)

2. Запустите `start-ssh-tunnel.bat` (оставьте окно открытым)

3. В Cursor настройте MCP сервер:
   - Settings -> MCP Servers
   - Добавьте сервер с типом "Command":
     - Command: `npx`
     - Args: 
       ```
       -y
       @supabase-community/mcp-server-supabase@latest
       --url=http://localhost:3100
       ```

### Вариант 2: Настройка через файл конфигурации

См. подробную инструкцию в `cursor-config-windows.md`

## Проверка работы

### На сервере:

```bash
# Проверить статус
systemctl status mcp-supabase

# Проверить логи
journalctl -u mcp-supabase -f

# Тестировать подключение
bash /opt/mcp-supabase-setup/test-connection.sh
```

### В Cursor:

1. Перезапустите Cursor
2. Откройте чат/командную панель
3. Попробуйте запрос:
   - "Покажи список таблиц в базе данных"
   - "Какие таблицы есть в Supabase?"

## Полезные команды

### Управление сервисом

```bash
# Запустить
systemctl start mcp-supabase

# Остановить
systemctl stop mcp-supabase

# Перезапустить
systemctl restart mcp-supabase

# Просмотр логов
journalctl -u mcp-supabase -f

# Статус
systemctl status mcp-supabase
```

### Обновление MCP сервера

```bash
npm update -g @supabase-community/mcp-server-supabase@latest
systemctl restart mcp-supabase
```

## Устранение проблем

### MCP сервер не запускается

1. Проверьте логи: `journalctl -u mcp-supabase -n 50`
2. Проверьте .env файл: `cat /opt/mcp-supabase/.env`
3. Проверьте подключение к Supabase:
   ```bash
   curl http://kong:8000/health
   ```

### Cursor не подключается

1. Убедитесь, что SSH туннель запущен
2. Проверьте подключение: `curl http://localhost:3100` (в PowerShell)
3. Перезапустите Cursor
4. Проверьте конфигурацию MCP в Cursor

## Следующие шаги

- Прочитайте полную документацию в `README.md`
- Настройте автоматическое резервное копирование
- Рассмотрите возможность использования reverse proxy (nginx) для безопасности
