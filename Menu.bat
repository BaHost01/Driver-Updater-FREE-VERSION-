@echo off
setlocal EnableDelayedExpansion

:: Variables
set "config_file=%~dp0config.json"
set "log_file=%~dp0update_log.txt"
set "latest_release_file=%~dp0latest_release.json"
set "downloads_dir=%~dp0downloads"

:: Function to log messages
:log
echo [%date% %time%] %* >> "%log_file%"
goto :eof

:: Function to read a value from a JSON file
:get_json_value
set "json_file=%1"
set "key=%2"
for /f "tokens=2 delims=:," %%A in ('findstr /i /c:"%key%" "%json_file%"') do set "value=%%A"
set "value=%value:~1,-1%"
goto :eof

:: Read configuration values from the JSON file
call :get_json_value "%config_file%" "update_check_url"
set "update_check_url=%value%"

call :get_json_value "%config_file%" "current_version"
set "current_version=%value%"

:: Check for updates by getting the latest release from GitHub
:check_for_updates
echo Checking for updates... >> "%log_file%"

:: Download the latest release information from GitHub
powershell -command "(New-Object System.Net.WebClient).DownloadFile('%update_check_url%', '%latest_release_file%')" 2>> "%log_file%"
if errorlevel 1 (
    echo Error downloading the latest release information. >> "%log_file%"
    echo Failed to download the latest release information.
    pause
    exit /b 1
)

:: Get the latest version tag
call :get_json_value "%latest_release_file%" "tag_name"
set "latest_version=%value%"

:: Compare the latest version with the current version
echo Current version: %current_version% >> "%log_file%"
echo Latest version: %latest_version% >> "%log_file%"

if "%current_version%" == "%latest_version%" (
    echo No update available. >> "%log_file%"
    echo The script is up to date.
    exit /b
) else (
    echo New version available: %latest_version% >> "%log_file%"
    echo Downloading the update... >> "%log_file%"
    
    :: Create the downloads directory if it doesn't exist
    if not exist "%downloads_dir%" mkdir "%downloads_dir%"

    :: Loop through each asset in the release and download it
    for /f "tokens=1,2 delims=," %%A in ('powershell -command "((Get-Content '%latest_release_file%' | ConvertFrom-Json).assets | ForEach-Object { $_.browser_download_url, $_.name })"') do (
        set "download_url=%%A"
        set "file_name=%%B"
        echo Downloading %%B... >> "%log_file%"
        powershell -command "(New-Object System.Net.WebClient).DownloadFile('!download_url!', '%downloads_dir%\!file_name!')" 2>> "%log_file%"
        if errorlevel 1 (
            echo Error downloading %%B. >> "%log_file%"
            echo Failed to download %%B.
        ) else (
            echo %%B downloaded successfully. >> "%log_file%"
        )
    )
)

:: Update the current version in the config.json file
powershell -command "(Get-Content '%config_file%') -replace '\"current_version\": \".*\"', '\"current_version\": \"%latest_version%\"' | Set-Content '%config_file%'" 2>> "%log_file%"
if errorlevel 1 (
    echo Error updating the current version in config.json. >> "%log_file%"
    echo Failed to update the current version.
) else (
    echo Current version updated to %latest_version%. >> "%log_file%"
)

echo Update complete. >> "%log_file%"
pause
