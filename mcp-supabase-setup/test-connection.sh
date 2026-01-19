#!/bin/bash

# Скрипт для тестирования подключения к MCP серверу
# Использование: ./test-connection.sh [url]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MCP_URL=${1:-"http://localhost:3100"}

echo -e "${BLUE}=== Тестирование подключения к MCP серверу ===${NC}"
echo -e "URL: ${MCP_URL}"
echo ""

# Тест 1: Проверка доступности сервера
echo -e "${YELLOW}[1] Проверка доступности сервера...${NC}"
if curl -s -f "${MCP_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Сервер доступен${NC}"
elif curl -s -f "${MCP_URL}" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Сервер отвечает (health endpoint может быть недоступен)${NC}"
else
    echo -e "${RED}✗ Сервер недоступен по адресу ${MCP_URL}${NC}"
    echo -e "${YELLOW}Проверьте:${NC}"
    echo "  - Запущен ли MCP сервер: systemctl status mcp-supabase"
    echo "  - Правильность URL"
    echo "  - Настроен ли SSH туннель (если используете)"
    exit 1
fi

# Тест 2: Проверка MCP протокола (если доступен)
echo -e "${YELLOW}[2] Проверка MCP протокола...${NC}"
MCP_TEST_RESPONSE=$(curl -s -X POST "${MCP_URL}/mcp" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -H "MCP-Protocol-Version: 2025-06-18" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-06-18",
            "capabilities": {},
            "clientInfo": {
                "name": "test-client",
                "version": "1.0.0"
            }
        }
    }' 2>/dev/null || echo "")

if [ -n "$MCP_TEST_RESPONSE" ]; then
    echo -e "${GREEN}✓ MCP протокол работает${NC}"
    echo -e "${BLUE}Ответ сервера:${NC}"
    echo "$MCP_TEST_RESPONSE" | head -c 200
    echo "..."
else
    echo -e "${YELLOW}⚠ MCP endpoint может требовать другой путь или аутентификацию${NC}"
fi

# Тест 3: Проверка подключения к Supabase (если доступны логи)
echo -e "${YELLOW}[3] Проверка статуса service...${NC}"
if systemctl is-active --quiet mcp-supabase; then
    echo -e "${GREEN}✓ MCP service запущен${NC}"
    
    # Проверка последних логов на наличие ошибок
    RECENT_ERRORS=$(journalctl -u mcp-supabase --since "1 minute ago" --no-pager | grep -i "error\|fail" || true)
    if [ -n "$RECENT_ERRORS" ]; then
        echo -e "${RED}⚠ Обнаружены ошибки в логах:${NC}"
        echo "$RECENT_ERRORS" | head -5
    else
        echo -e "${GREEN}✓ Ошибок в логах не обнаружено${NC}"
    fi
else
    echo -e "${RED}✗ MCP service не запущен${NC}"
    echo -e "${YELLOW}Запустите: systemctl start mcp-supabase${NC}"
fi

echo ""
echo -e "${BLUE}=== Тестирование завершено ===${NC}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Если все тесты пройдены, настройте Cursor для подключения"
echo "2. Если есть ошибки, проверьте логи: journalctl -u mcp-supabase -f"
echo "3. Убедитесь, что переменные окружения в .env правильные"
