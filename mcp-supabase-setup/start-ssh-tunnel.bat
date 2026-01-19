@echo off
REM Скрипт для создания SSH туннеля к MCP серверу на Windows
REM Использование: Замените параметры ниже и запустите этот файл

REM Параметры подключения (измените под ваши данные)
set REMOTE_HOST=your-server.timeweb.cloud
set REMOTE_USER=root
set REMOTE_PORT=3100
set LOCAL_PORT=3100

echo ========================================
echo SSH Tunnel to MCP Server
echo ========================================
echo.
echo Remote Server: %REMOTE_USER%@%REMOTE_HOST%
echo Remote Port: %REMOTE_PORT%
echo Local Port: %LOCAL_PORT%
echo.
echo Tunnel: localhost:%LOCAL_PORT% -^> %REMOTE_HOST%:%REMOTE_PORT%
echo.
echo Press Ctrl+C to stop the tunnel
echo ========================================
echo.

REM Проверка наличия SSH
where ssh >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: SSH not found!
    echo Please install Git Bash or OpenSSH for Windows
    echo.
    pause
    exit /b 1
)

REM Создание SSH туннеля
ssh -N -L %LOCAL_PORT%:localhost:%REMOTE_PORT% %REMOTE_USER%@%REMOTE_HOST%

pause
