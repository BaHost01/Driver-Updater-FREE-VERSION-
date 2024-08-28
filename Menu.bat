@echo off
setlocal EnableDelayedExpansion

:: Variables
set "config_file=%~dp0config.json"
set "log_file="
set "latest_release_file=%~dp0latest_release.json"
set "downloads_dir="
set "current_version="
set "latest_version="
set "auto_update="
set "backup_old_version="

:: Function to log messages
:log
echo [%date% %time%] %* >> "%log_file%"
goto :eof

:: Function to read a value from a JSON file
:get_json_value
set "json_file=%1"
set "key=%2"
set "value="
for /f "tokens=1* delims=:," %%A in ('findstr /i /c:"%key%" "%json_file%"') do (
    set "value=%%B"
    set "value=!value:~1,-1!"
)
goto :eof

:: Function to initialize configuration
:init_config
call :get_json_value "%config_file%" "update_log_file"
set "log_file=%~dp0!value!"

call :get_json_value "%config_file%" "download_directory"
set "downloads_dir=%~dp0!value!"

call :get_json_value "%config_file%" "current_version"
set "current_version=!value!"

call :get_json_value "%config_file%" "auto_update"
set "auto_update=!value!"

call :get_json_value "%config_file%" "backup_old_version"
set "backup_old_version=!value!"

:: Function to backup old version
:backup_old_version
if "%backup_old_version%" == "true" (
    set "backup_dir=%~dp0backup_%current_version%"
    if not exist "%backup_dir%" mkdir "%backup_dir%"
    copy "%downloads_dir%\*" "%backup_dir%\*" >nul
    if errorlevel 1 (
        call :log "Error creating backup of old version."
        echo Failed to backup old version.
        goto :eof
    )
    call :log "Backup of old version created at %backup_dir%."
    echo Old version backed up successfully.
)
goto :eof

:: Function to simulate a download progress bar
:progress_bar
set /a total=50
set /a completed=0
set "bar="
for /L %%i in (1,1,%total%) do set "bar=!bar!_"
set "download_complete="

:: Simulate the download with a progress bar
:download_loop
cls
echo Downloading... [!bar!]
timeout /t 1 >nul
set /a completed+=5
set "bar=["
for /L %%i in (1,1,!completed!) do set "bar=!bar!#"
for /L %%i in (!completed!,1,%total%) do set "bar=!bar!_"
set "bar=!bar!]"

if !completed! lss %total% goto download_loop
set "download_complete=Download Complete"
echo !download_complete!
goto :eof

:: Function to download the latest release from GitHub
:download_latest_release
echo Checking for updates...
call :log "Checking for updates..."

:: Download the latest release information from GitHub
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%update_check_url%', '%latest_release_file%')" 2>> "%log_file%"
if errorlevel 1 (
    call :log "Error downloading the latest release information."
    echo Failed to download the latest release information.
    pause
    exit /b 1
)

:: Get the latest version tag
call :get_json_value "%latest_release_file%" "tag_name"
set "latest_version=!value!"

:: Compare the latest version with the current version
echo Current version: %current_version%
call :log "Current version: %current_version%"

echo Latest version: %latest_version%
call :log "Latest version: %latest_version%"

if "%current_version%" == "%latest_version%" (
    echo No update available.
    call :log "No update available. Script is up to date."
    exit /b
)

:: If update is available, proceed to download files
call :log "New version available: %latest_version%. Downloading update..."
call :backup_old_version

if not exist "%downloads_dir%" mkdir "%downloads_dir%"

for /f "delims=" %%A in ('powershell -command "(Get-Content '%config_file%' | ConvertFrom-Json).files_to_download"') do (
    set "file_name=%%A"
    set "download_url=%download_base_url:{tag}=%latest_version%!file_name!"
    echo Downloading !file_name!...
    call :log "Downloading !file_name! from !download_url!..."
    
    :: Simulate the download progress
    call :progress_bar

    powershell -command "(New-Object System.Net.WebClient).DownloadFile('!download_url!', '%downloads_dir%\!file_name!')" 2>> "%log_file%"
    if errorlevel 1 (
        call :log "Error downloading !file_name!."
        echo Failed to download !file_name!.
    ) else (
        call :log "!file_name! downloaded successfully."
        echo !file_name! downloaded successfully.
    )
)

:: Update the current version in the config.json file
powershell -command "(Get-Content '%config_file%') -replace '\"current_version\": \".*\"', '\"current_version\": \"%latest_version%\"' | Set-Content '%config_file%'" 2>> "%log_file%"
if errorlevel 1 (
    call :log "Error updating the current version in config.json."
    echo Failed to update the current version.
) else (
    call :log "Current version updated to %latest_version%."
    echo Current version updated to %latest_version%.
)

:: Check if auto-update is enabled
if "%auto_update%" == "true" (
    echo Auto-update is enabled. Running the update script...
    call :log "Auto-update is enabled. Executing update script."
    if exist "%downloads_dir%\update_script.bat" (
        call "%downloads_dir%\update_script.bat"
    ) else (
        call :log "Update script not found."
        echo Update script not found.
    )
) else (
    echo Auto-update is disabled. Update manually if needed.
    call :log "Auto-update is disabled."
)

echo Update complete.
pause
exit /b

:: Initialize configuration
:init_config

:: Start update process
:download_latest_release
