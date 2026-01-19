#!/bin/bash

# Скрипт для настройки Kong API Gateway для доступа к MCP endpoint
# Внимание: Этот скрипт должен быть запущен в директории Supabase с docker-compose.yml

set -e

echo "=== Настройка Kong для MCP endpoint ==="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

KONG_CONFIG="./volumes/api/kong.yml"

if [ ! -f "$KONG_CONFIG" ]; then
    echo -e "${RED}Ошибка: Файл ${KONG_CONFIG} не найден${NC}"
    echo "Убедитесь, что вы находитесь в директории Supabase"
    exit 1
fi

# Определение IP Docker bridge gateway
echo -e "${GREEN}Определение IP Docker bridge gateway...${NC}"
BRIDGE_IP=$(docker inspect supabase-kong --format '{{range .NetworkSettings.Networks}}{{println .Gateway}}{{end}}' 2>/dev/null | head -n1 | tr -d ' ')

if [ -z "$BRIDGE_IP" ]; then
    echo -e "${YELLOW}Не удалось автоматически определить IP. Используйте 172.18.0.1 или укажите вручную${NC}"
    read -p "Введите IP Docker bridge (или нажмите Enter для 172.18.0.1): " BRIDGE_IP
    BRIDGE_IP=${BRIDGE_IP:-172.18.0.1}
fi

echo -e "${GREEN}Используется IP: ${BRIDGE_IP}${NC}"

# Создание резервной копии
cp "$KONG_CONFIG" "${KONG_CONFIG}.backup"
echo -e "${GREEN}Создана резервная копия: ${KONG_CONFIG}.backup${NC}"

# Проверка наличия секции MCP в конфигурации
if grep -q "name: mcp" "$KONG_CONFIG"; then
    echo -e "${GREEN}Найдена секция MCP в конфигурации${NC}"
    echo -e "${YELLOW}Пожалуйста, вручную отредактируйте файл ${KONG_CONFIG}:${NC}"
    echo "1. Найдите секцию с 'name: mcp'"
    echo "2. Закомментируйте или удалите плагин 'request-termination'"
    echo "3. В секции 'allow' добавьте IP: ${BRIDGE_IP}"
else
    echo -e "${YELLOW}Секция MCP не найдена в конфигурации. Возможно, нужна другая настройка.${NC}"
fi

echo ""
echo -e "${GREEN}После редактирования выполните:${NC}"
echo "docker-compose restart kong"
echo "или перезапустите контейнер Supabase"
