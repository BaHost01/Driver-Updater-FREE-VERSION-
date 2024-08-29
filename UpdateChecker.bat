@echo off
setlocal

:: Caminho do arquivo de configuração
set "config_file=config.json"

:: Função para ler a versão atual do config.json
for /f "tokens=2 delims=: " %%a in ('findstr /r /c:"\"version\"" "%config_file%"') do (
    set "current_version=%%a"
    set "current_version=!current_version:,=!"
    set "current_version=!current_version:"=!"
)

:: URL de atualização (lido do config.json)
for /f "tokens=2 delims=: " %%a in ('findstr /r /c:"\"update_url\"" "%config_file%"') do (
    set "update_url=%%a"
    set "update_url=!update_url:,=!"
    set "update_url=!update_url:"=!"
)

:: Baixar a última versão
powershell -command "Invoke-WebRequest -Uri '!update_url!' -OutFile '%~dp0latest_update.zip'"
:: Descompactar e substituir os arquivos
powershell -command "Expand-Archive -Path '%~dp0latest_update.zip' -DestinationPath '%~dp0update'"

:: Exibir mensagem de atualização bem-sucedida
echo Atualizacao para a versao !current_version! concluida com sucesso.
pause
