@echo off
setlocal EnableDelayedExpansion

:: Variáveis do arquivo JSON
set "config_file=%~dp0config.json"
set "log_file=%~dp0update_log.txt"
set "latest_version_file=%~dp0latest_version.json"
set "update_script_file=%~dp0update_script.bat"

:: Função de log
:log
echo [%date% %time%] %* >> "%log_file%"
goto :eof

:: Função para ler valor do JSON
:get_json_value
set "json_file=%1"
set "key=%2"
for /f "tokens=2 delims=:," %%A in ('findstr /i /c:"%key%" "%json_file%"') do set "value=%%A"
set "value=%value:~1,-1%"
goto :eof

:: Obter configurações do arquivo JSON
call :get_json_value "%config_file%" "update_check_url"
set "update_check_url=%value%"

call :get_json_value "%config_file%" "download_url"
set "download_url=%value%"

call :get_json_value "%config_file%" "current_version"
set "current_version=%value%"

:: Função para verificar se há uma atualização disponível
:check_for_updates
echo Verificando se há atualizações disponíveis... >> "%log_file%"

:: Baixar a versão mais recente usando a API do GitHub
echo Baixando o arquivo de versão mais recente... >> "%log_file%"
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%update_check_url%', '%latest_version_file%')" 2>> "%log_file%"
if errorlevel 1 (
    echo Erro ao baixar o arquivo de versão mais recente. >> "%log_file%"
    echo Falha ao baixar o arquivo de versão mais recente.
    pause
    exit /b 1
)

:: Ler a versão mais recente do JSON baixado
call :get_json_value "%latest_version_file%" "tag_name"
set "latest_version=%value%"

echo Versão atual: %current_version% >> "%log_file%"
echo Versão mais recente: %latest_version% >> "%log_file%"

if "%current_version%" == "%latest_version%" (
    echo Nenhuma atualização disponível. >> "%log_file%"
    echo O script está na versão mais recente.
    exit /b
) else (
    echo Nova versão disponível: %latest_version% >> "%log_file%"
    echo Baixando a atualização... >> "%log_file%"
    
    :: Formatar URL de download
    set "formatted_download_url=%download_url:{tag}=%latest_version%"
    powershell -command "(New-Object System.Net.WebClient).DownloadFile('%formatted_download_url%', '%update_script_file%')" 2>> "%log_file%"
    if errorlevel 1 (
        echo Erro ao baixar o novo script. >> "%log_file%"
        echo Falha ao baixar o novo script.
        pause
        exit /b 1
    )
    
    echo Atualização concluída. >> "%log_file%"
    echo Novo script baixado e pronto para execução.
)

:: Atualizar e reiniciar
echo Atualizando o script... >> "%log_file%"
if exist "%update_script_file%" (
    echo Executando o novo script de atualização. >> "%log_file%"
    call "%update_script_file%"
) else (
    echo Falha ao atualizar o script. >> "%log_file%"
    echo O script de atualização não foi encontrado.
)

pause
