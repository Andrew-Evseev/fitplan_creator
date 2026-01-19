#!/bin/bash

# Альтернативная установка для self-hosted Supabase
# Для self-hosted Supabase MCP endpoint встроен, отдельная установка не требуется

set -e

echo "=== Настройка MCP для self-hosted Supabase ==="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Для self-hosted Supabase MCP сервер встроен!${NC}"
echo -e "${YELLOW}Вам нужно только:${NC}"
echo ""
echo "1. Включить MCP endpoint в конфигурации Supabase (Kong)"
echo "2. Настроить доступ к MCP endpoint"
echo "3. Использовать MCP endpoint напрямую через HTTP"
echo ""
echo -e "${GREEN}Следующие шаги:${NC}"
echo "1. Запустите скрипт setup-kong.sh для настройки Kong"
echo "2. Настройте доступ к /mcp endpoint"
echo "3. Используйте HTTP подключение в Cursor вместо команды npx"
echo ""
echo -e "${YELLOW}Документация:${NC}"
echo "https://supabase.com/docs/guides/self-hosting/enable-mcp"
