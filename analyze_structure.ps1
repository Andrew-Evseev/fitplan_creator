function Show-Tree {
    param(
        [string]\ = ".",
        [int]\ = 10,
        [string]\ = ""
    )
    
    \ = Get-Item \
    if (\.PSIsContainer) {
        Write-Host "\├── [\]/" -ForegroundColor Cyan
        \ = "\│   "
        
        # олучаем все подпапки
        \ = Get-ChildItem -Path \ -Directory | Sort-Object Name
        \ = Get-ChildItem -Path \ -File | Where-Object { \.Extension -eq '.dart' } | Sort-Object Name
        
        # ыводим папки
        foreach (\ in \) {
            if (\ -gt 1) {
                Show-Tree -Path \.FullName -Depth (\ - 1) -Indent \
            } else {
                Write-Host "\├── [\]/" -ForegroundColor Cyan
            }
        }
        
        # ыводим Dart файлы
        foreach (\ in \) {
            Write-Host "\├── \" -ForegroundColor Green
        }
        
        # ыводим остальные файлы (не Dart)
        \ = Get-ChildItem -Path \ -File | Where-Object { \.Extension -ne '.dart' }
        if (\) {
            foreach (\ in \) {
                Write-Host "\├── \" -ForegroundColor Gray
            }
        }
    }
}

Write-Host "
📁 Я СТТ Т:
" -ForegroundColor Yellow
Show-Tree -Path ".\lib" -Depth 10
