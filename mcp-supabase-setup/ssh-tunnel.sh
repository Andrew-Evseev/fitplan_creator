#!/bin/bash

# Скрипт для создания SSH туннеля к MCP серверу
# Использование: ./ssh-tunnel.sh [remote_port] [local_port]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Параметры подключения (измените под ваши данные)
REMOTE_HOST="your-server.timeweb.cloud"
REMOTE_USER="root"
REMOTE_PORT=${1:-3100}  # Порт MCP сервера на удаленном сервере
LOCAL_PORT=${2:-3100}   # Локальный порт для туннеля

echo -e "${GREEN}=== Создание SSH туннеля к MCP серверу ===${NC}"
echo "Удаленный сервер: ${REMOTE_USER}@${REMOTE_HOST}"
echo "Удаленный порт: ${REMOTE_PORT}"
echo "Локальный порт: ${LOCAL_PORT}"
echo ""
echo -e "${YELLOW}Для использования этого скрипта:${NC}"
echo "1. Отредактируйте переменные REMOTE_HOST и REMOTE_USER"
echo "2. Убедитесь, что настроен SSH ключ для подключения"
echo "3. Запустите скрипт: ./ssh-tunnel.sh"
echo ""
echo -e "${YELLOW}Туннель будет создан: localhost:${LOCAL_PORT} -> ${REMOTE_HOST}:${REMOTE_PORT}${NC}"
echo "Для остановки нажмите Ctrl+C"
echo ""

# Создание SSH туннеля
ssh -N -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}
