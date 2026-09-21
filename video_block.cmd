@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Video / SNS Block Manager

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "AUTH=%ProgramData%\VideoBlock\video_block.auth"
set "DEFAULT_HASH=8FD2E770200E4E59123A38B0E00B16E4C3EAF57A962F2537BB069A98BD9EE10E"
set "TAG=WinVideoBlock"
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
echo Installing Windows NRPT domain-suffix blocking rules...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$tag='%TAG%'; $domains=@('.youtube.com','.youtu.be','.youtube-nocookie.com','.youtubei.googleapis.com','.youtube.googleapis.com','.googlevideo.com','.ytimg.com','.ggpht.com','.instagram.com','.cdninstagram.com','.tiktok.com','.tiktokcdn.com','.tiktokv.com','.musical.ly','.chzzk.naver.com','.openapi.chzzk.naver.com','.tv.naver.com','.twitch.tv','.ttvnw.net'); Get-DnsClientNrptRule -ErrorAction SilentlyContinue | Where-Object {$_.Comment -eq $tag} | Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue; foreach($d in $domains){Add-DnsClientNrptRule -Namespace $d -NameServers '127.0.0.1' -Comment $tag -ErrorAction Stop | Out-Null}"
if not "%errorlevel%"=="0" (
    echo.
    echo Failed to install NRPT rules.
    echo This feature requires a Windows edition that provides DnsClient NRPT cmdlets.
    pause
    goto MENU
)
ipconfig /flushdns >nul
echo.
echo Blocking enabled.
echo Dynamic subdomains such as xxx.googlevideo.com are covered by suffix rules.
echo.
echo IMPORTANT: Browser Secure DNS / DNS-over-HTTPS can bypass OS DNS policy
echo in some configurations. Set browser Secure DNS to OS/default if needed.
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-DnsClientNrptRule -ErrorAction SilentlyContinue | Where-Object {$_.Comment -eq '%TAG%'} | Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue"
call :REMOVE_LEGACY_HOSTS
ipconfig /flushdns >nul
echo Blocking disabled.
pause
goto MENU

:STATUS
echo.
for /f "delims=" %%C in ('powershell -NoProfile -Command "@(Get-DnsClientNrptRule -ErrorAction SilentlyContinue | Where-Object {$_.Comment -eq '%TAG%'}).Count"') do set "RULECOUNT=%%C"
if "%RULECOUNT%"=="0" (
    echo STATUS: BLOCKING DISABLED
) else (
    echo STATUS: BLOCKING ENABLED
    echo NRPT rules: %RULECOUNT%
)
echo.
echo Test with:
echo   nslookup xxx.googlevideo.com
echo When blocking is active, normal DNS resolution should fail.
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

:REMOVE_LEGACY_HOSTS
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "BEGIN_MARK=# === VIDEO_BLOCK_BEGIN ==="
set "END_MARK=# === VIDEO_BLOCK_END ==="
findstr /L /C:"%BEGIN_MARK%" "%HOSTS%" >nul 2>&1
if not "%errorlevel%"=="0" exit /b
set "TMP=%TEMP%\video_block_hosts_%RANDOM%.tmp"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%HOSTS%'; $b='%BEGIN_MARK%'; $e='%END_MARK%'; $inside=$false; $out=foreach($line in [IO.File]::ReadAllLines($p)){if($line -eq $b){$inside=$true;continue};if($line -eq $e){$inside=$false;continue};if(-not $inside){$line}}; [IO.File]::WriteAllLines('%TMP%',$out,(New-Object Text.UTF8Encoding($false)))"
if exist "%TMP%" (
    copy /y "%TMP%" "%HOSTS%" >nul
    del /q "%TMP%" >nul 2>&1
)
exit /b
