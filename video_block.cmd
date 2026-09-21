@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Video / SNS Block Manager

:: Re-launch as Administrator if needed.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "BACKUP=%SystemRoot%\System32\drivers\etc\hosts.video_block_backup"
set "BEGIN_MARK=# === VIDEO_BLOCK_BEGIN ==="
set "END_MARK=# === VIDEO_BLOCK_END ==="
set "AUTH=%ProgramData%\VideoBlock\video_block.auth"
set "DEFAULT_HASH=8FD2E770200E4E59123A38B0E00B16E4C3EAF57A962F2537BB069A98BD9EE10E"
if not exist "%ProgramData%\VideoBlock" mkdir "%ProgramData%\VideoBlock" >nul 2>&1
if not exist "%AUTH%" >"%AUTH%" echo NOSALT^|%DEFAULT_HASH%

:MENU
cls
echo ==========================================
echo        Video / SNS Block Manager
echo ==========================================
echo.
echo   1. Block video / SNS
echo   2. Unblock  [Password required]
echo   3. Check status
echo   4. Change password
echo   5. Exit
echo.
set /p "CHOICE=Select: "

if "%CHOICE%"=="1" goto BLOCK
if "%CHOICE%"=="2" goto UNBLOCK_AUTH
if "%CHOICE%"=="3" goto STATUS
if "%CHOICE%"=="4" goto CHANGE_PASSWORD
if "%CHOICE%"=="5" exit /b
goto MENU

:BLOCK
echo.
findstr /L /C:"%BEGIN_MARK%" "%HOSTS%" >nul 2>&1
if "%errorlevel%"=="0" (
    echo Blocking is already enabled.
    pause
    goto MENU
)
if not exist "%BACKUP%" copy /y "%HOSTS%" "%BACKUP%" >nul
>>"%HOSTS%" echo.
>>"%HOSTS%" echo %BEGIN_MARK%
>>"%HOSTS%" echo # Managed by video_block.cmd
>>"%HOSTS%" echo # YouTube
for %%H in (
youtube.com www.youtube.com m.youtube.com music.youtube.com tv.youtube.com
youtu.be www.youtu.be youtube-nocookie.com www.youtube-nocookie.com
youtubei.googleapis.com youtube.googleapis.com youtube-ui.l.google.com youtube.l.google.com
googlevideo.com ytimg.com www.ytimg.com i.ytimg.com s.ytimg.com ytimg.l.google.com yt3.ggpht.com
) do >>"%HOSTS%" echo 0.0.0.0 %%H
>>"%HOSTS%" echo # Instagram
for %%H in (
instagram.com www.instagram.com m.instagram.com i.instagram.com api.instagram.com
graph.instagram.com l.instagram.com cdninstagram.com www.cdninstagram.com
) do >>"%HOSTS%" echo 0.0.0.0 %%H
>>"%HOSTS%" echo # TikTok
for %%H in (
tiktok.com www.tiktok.com m.tiktok.com api.tiktok.com
tiktokcdn.com www.tiktokcdn.com tiktokv.com www.tiktokv.com
musical.ly www.musical.ly
) do >>"%HOSTS%" echo 0.0.0.0 %%H
>>"%HOSTS%" echo # CHZZK / Naver video entry points
for %%H in (
chzzk.naver.com openapi.chzzk.naver.com
tv.naver.com m.tv.naver.com
) do >>"%HOSTS%" echo 0.0.0.0 %%H
>>"%HOSTS%" echo # Twitch
for %%H in (
twitch.tv www.twitch.tv m.twitch.tv player.twitch.tv
api.twitch.tv gql.twitch.tv usher.ttvnw.net
) do >>"%HOSTS%" echo 0.0.0.0 %%H
>>"%HOSTS%" echo %END_MARK%
ipconfig /flushdns >nul
echo.
echo Blocking enabled.
echo Existing hosts file was preserved.
echo.
echo NOTE:
echo hosts does not support wildcards such as *.googlevideo.com.
echo Dynamic CDN subdomains may therefore bypass this version.
pause
goto MENU

:UNBLOCK_AUTH
echo.
echo Enter password to disable blocking.
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$p=Read-Host 'Password' -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)} finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}"`) do set "PW=%%P"
call :VERIFY_PASSWORD
if not "%AUTH_OK%"=="1" (
    echo.
    echo Incorrect password.
    timeout /t 2 >nul
    goto MENU
)
goto UNBLOCK

:UNBLOCK
echo.
findstr /L /C:"%BEGIN_MARK%" "%HOSTS%" >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Blocking is already disabled.
    pause
    goto MENU
)
set "TMP=%TEMP%\video_block_hosts_%RANDOM%.tmp"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$p='%HOSTS%'; $b='%BEGIN_MARK%'; $e='%END_MARK%'; $inside=$false; $out=foreach($line in [IO.File]::ReadAllLines($p)){if($line -eq $b){$inside=$true;continue};if($line -eq $e){$inside=$false;continue};if(-not $inside){$line}}; [IO.File]::WriteAllLines('%TMP%',$out,(New-Object Text.UTF8Encoding($false)))"
if not exist "%TMP%" (
    echo Failed to create temporary hosts file.
    pause
    goto MENU
)
copy /y "%TMP%" "%HOSTS%" >nul
del /q "%TMP%" >nul 2>&1
ipconfig /flushdns >nul
echo Blocking disabled.
pause
goto MENU

:STATUS
echo.
findstr /L /C:"%BEGIN_MARK%" "%HOSTS%" >nul 2>&1
if "%errorlevel%"=="0" (echo STATUS: BLOCKING ENABLED) else (echo STATUS: BLOCKING DISABLED)
echo.
echo Hosts: %HOSTS%
if exist "%BACKUP%" echo Backup: %BACKUP%
pause
goto MENU

:CHANGE_PASSWORD
echo.
echo Verify current password.
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$p=Read-Host 'Current password' -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)} finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}"`) do set "PW=%%P"
call :VERIFY_PASSWORD
if not "%AUTH_OK%"=="1" (
    echo.
    echo Incorrect current password.
    timeout /t 2 >nul
    goto MENU
)
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$p=Read-Host 'New password' -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)} finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}"`) do set "NEWPW=%%P"
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$p=Read-Host 'Confirm new password' -AsSecureString; $b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b)} finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}"`) do set "NEWPW2=%%P"
if not "%NEWPW%"=="%NEWPW2%" (
    set "NEWPW="
    set "NEWPW2="
    echo.
    echo Passwords do not match.
    pause
    goto MENU
)
if "%NEWPW%"=="" (
    echo Password cannot be empty.
    pause
    goto MENU
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$salt=New-Object byte[] 16; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt); $saltHex=([BitConverter]::ToString($salt)).Replace('-',''); $pw=$env:NEWPW; $sha=[Security.Cryptography.SHA256]::Create(); try {$h=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($saltHex+$pw)))).Replace('-',''); [IO.File]::WriteAllText($env:AUTH,$saltHex+'|'+$h,(New-Object Text.UTF8Encoding($false)))} finally {$sha.Dispose()}"
set "NEWPW="
set "NEWPW2="
echo.
echo Password changed successfully.
pause
goto MENU

:VERIFY_PASSWORD
set "AUTH_OK=0"
for /f "tokens=1,2 delims=|" %%A in (%AUTH%) do (
    set "SALT=%%A"
    set "STORED=%%B"
)
for /f "delims=" %%H in ('powershell -NoProfile -Command "$salt=$env:SALT; $pw=$env:PW; if($salt -eq 'NOSALT'){$v=$pw}else{$v=$salt+$pw}; $sha=[Security.Cryptography.SHA256]::Create(); try {([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($v)))).Replace('-','')} finally {$sha.Dispose()}"') do set "INPUTHASH=%%H"
set "PW="
if /I "%INPUTHASH%"=="%STORED%" set "AUTH_OK=1"
exit /b
