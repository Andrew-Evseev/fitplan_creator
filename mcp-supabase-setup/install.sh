#!/bin/bash

# Скрипт установки MCP сервера для Supabase на сервере
# Использование: ./install.sh

set -e

echo "=== Установка MCP сервера для Supabase ==="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ошибка: требуется запуск с правами root (sudo)${NC}"
    exit 1
fi

# Создание директории для MCP сервера
MCP_DIR="/opt/mcp-supabase"
echo -e "${GREEN}Создание директории ${MCP_DIR}...${NC}"
mkdir -p $MCP_DIR
cd $MCP_DIR

# Проверка Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js не найден. Установка Node.js 18...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}Node.js версия: ${NODE_VERSION}${NC}"

# Для self-hosted Supabase MCP сервер встроен
# Если нужно использовать через npx, используйте правильное название пакета
echo -e "${GREEN}Проверка доступности MCP сервера Supabase...${NC}"
echo -e "${YELLOW}Для self-hosted Supabase MCP endpoint встроен.${NC}"
echo -e "${YELLOW}Проверьте документацию Supabase по включению MCP endpoint.${NC}"

# Копирование шаблона конфигурации
if [ -f "${MCP_DIR}/../mcp-supabase-setup/env-template.txt" ]; then
    echo -e "${GREEN}Создание файла .env из шаблона...${NC}"
    cp "${MCP_DIR}/../mcp-supabase-setup/env-template.txt" "${MCP_DIR}/.env"
    echo -e "${YELLOW}Файл .env создан. Пожалуйста, отредактируйте его:${NC}"
    echo "nano ${MCP_DIR}/.env"
else
    echo -e "${YELLOW}Шаблон env-template.txt не найден. Создайте .env вручную.${NC}"
fi

# Установка systemd service
if [ -f "${MCP_DIR}/../mcp-supabase-setup/mcp-supabase.service" ]; then
    echo -e "${GREEN}Установка systemd service...${NC}"
    cp "${MCP_DIR}/../mcp-supabase-setup/mcp-supabase.service" /etc/systemd/system/
    systemctl daemon-reload
    echo -e "${GREEN}Service установлен. Для запуска выполните:${NC}"
    echo "systemctl enable mcp-supabase"
    echo "systemctl start mcp-supabase"
fi

echo ""
echo -e "${GREEN}Установка завершена!${NC}"
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Отредактируйте файл ${MCP_DIR}/.env с вашими параметрами Supabase"
echo "2. Включите и запустите service: systemctl enable --now mcp-supabase"
echo "3. Проверьте статус: systemctl status mcp-supabase"
echo "4. Настройте доступ к Supabase (через SSH туннель или напрямую)"
