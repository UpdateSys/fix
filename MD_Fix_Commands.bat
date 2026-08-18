@echo off
title MD Fix Commands - Windows Error Fixer [All Versions]
color 0A
mode con: cols=70 lines=50

setlocal enabledelayedexpansion
set "WIN7=0"
set "WIN8=0"
set "WIN10=0"
set "WIN11=0"
set "OSNAME=Unknown"
set "VERSION=N/A"

for /f "tokens=2 delims=[]" %%v in ('ver 2^>nul') do set "FULLVER=%%v"
for /f "tokens=2-4 delims=. " %%a in ("%FULLVER%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
    set "BUILD=%%c"
)
set "VERSION=!MAJOR!.!MINOR!.!BUILD!"

if "!MAJOR!"=="6" (
    if "!MINOR!"=="1" (
        set "WIN7=1"
        set "OSNAME=Windows 7"
    )
    if "!MINOR!"=="2" (
        set "WIN8=1"
        set "OSNAME=Windows 8"
    )
    if "!MINOR!"=="3" (
        set "WIN8=1"
        set "OSNAME=Windows 8.1"
    )
)
if "!MAJOR!"=="10" (
    if !BUILD! GEQ 22000 (
        set "WIN11=1"
        set "OSNAME=Windows 11"
    ) else (
        set "WIN10=1"
        set "OSNAME=Windows 10"
    )
)

endlocal & (
    set "WIN7=%WIN7%"
    set "WIN8=%WIN8%"
    set "WIN10=%WIN10%"
    set "WIN11=%WIN11%"
    set "OSNAME=%OSNAME%"
    set "VERSION=%VERSION%"
)

:menu
cls
echo ============================================================
echo            MD Fix Commands
echo ============================================================
echo   Detected OS : %OSNAME%
echo   Version     : %VERSION%
echo ============================================================
echo.
echo   [1]  Reset Windows Update
echo   [2]  Fix System Files (SFC /Scannow)
echo   [3]  Fix DISM Health            [Win8+]
echo   [4]  Reset Windows Store Cache  [Win8+]
echo   [5]  Fix Network / DNS Reset
echo   [6]  Fix Windows Activation
echo   [7]  Fix Windows Firewall
echo   [8]  Fix Windows Explorer Crashes
echo   [9]  Clean Temp Files
echo   [a]  Fix Blue Screen (BSOD) Logs
echo   [b]  Fix Windows Search
echo   [c]  Reset Group Policy
echo   [d]  Fix USB Issues
echo   [e]  Disk Cleanup            [Win8+]
echo   [f]  Run All Fixes
echo   [0]  Exit
echo.
echo ============================================================
choice /c 123456789abcdef0 /n /m "  > "
if %errorlevel%==1 (call :fix_wupdate & goto menu)
if %errorlevel%==2 (call :fix_sfc & goto menu)
if %errorlevel%==3 (call :fix_dism & goto menu)
if %errorlevel%==4 (call :fix_store & goto menu)
if %errorlevel%==5 (call :fix_network & goto menu)
if %errorlevel%==6 (call :fix_activation & goto menu)
if %errorlevel%==7 (call :fix_firewall & goto menu)
if %errorlevel%==8 (call :fix_explorer & goto menu)
if %errorlevel%==9 (call :clean_temp & goto menu)
if %errorlevel%==10 (call :fix_bsod & goto menu)
if %errorlevel%==11 (call :fix_search & goto menu)
if %errorlevel%==12 (call :fix_grouppolicy & goto menu)
if %errorlevel%==13 (call :fix_usb & goto menu)
if %errorlevel%==14 (call :fix_diskcleanup & goto menu)
if %errorlevel%==15 (call :fix_all & goto menu)
if %errorlevel%==16 exit
goto menu

:fix_wupdate
cls
echo ============================================================
echo   [1] Resetting Windows Update...
echo ============================================================
echo.
net stop wuauserv 2>nul
net stop cryptSvc 2>nul
net stop bits 2>nul
net stop msiserver 2>nul
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old 2>nul
ren C:\Windows\System32\catroot2 catroot2.old 2>nul
net start wuauserv 2>nul
net start cryptSvc 2>nul
net start bits 2>nul
net start msiserver 2>nul
regsvr32.exe /s wuaueng.dll 2>nul
regsvr32.exe /s wuapi.dll 2>nul
regsvr32.exe /s wups.dll 2>nul
echo.
echo [OK] Windows Update has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_sfc
cls
echo ============================================================
echo   [2] Running System File Checker...
echo ============================================================
echo.
if "%WIN7%"=="0" (
    echo [STEP 1/2] Repairing Windows Image first...
    DISM /Online /Cleanup-Image /RestoreHealth 2>nul
    echo.
)
echo [STEP 2/2] Scanning system files...
echo Please wait, this may take a while...
echo.
sfc /scannow
echo.
echo [OK] System File Checker completed!
timeout /t 2 /nobreak >nul
exit /b

:fix_dism
cls
echo ============================================================
echo   [3] Fixing DISM Health...
echo ============================================================
echo.
if "%WIN7%"=="1" (
    echo [SKIP] DISM is not available on Windows 7.
    echo        Use System Update Readiness Tool instead.
    timeout /t 3 /nobreak >nul
    exit /b
)
echo [STEP 1/3] Checking health...
DISM /Online /Cleanup-Image /CheckHealth
echo.
echo [STEP 2/3] Scanning health...
DISM /Online /Cleanup-Image /ScanHealth
echo.
echo [STEP 3/3] Restoring health...
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo [OK] DISM Health repair completed!
timeout /t 2 /nobreak >nul
exit /b

:fix_store
cls
echo ============================================================
echo   [4] Resetting Windows Store Cache...
echo ============================================================
echo.
if "%WIN7%"=="1" (
    echo [SKIP] Windows Store is not available on Windows 7.
    timeout /t 3 /nobreak >nul
    exit /b
)
net stop InstallService 2>nul
wsreset.exe 2>nul
net start InstallService 2>nul
powershell -Command "Get-AppxPackage *WindowsStore* | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}" 2>nul
echo.
echo [OK] Windows Store has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_network
cls
echo ============================================================
echo   [5] Resetting Network and DNS...
echo ============================================================
echo.
ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh winsock reset
netsh int ip reset
netsh interface ip set dns "Ethernet" static 8.8.8.8 2>nul
netsh interface ip add dns "Ethernet" 8.8.4.4 index=2 2>nul
netsh interface ip set dns "Wi-Fi" static 8.8.8.8 2>nul
netsh interface ip add dns "Wi-Fi" 8.8.4.4 index=2 2>nul
netsh interface ip set dns "Local Area Connection" static 8.8.8.8 2>nul
netsh interface ip add dns "Local Area Connection" 8.8.4.4 index=2 2>nul
echo.
echo [OK] Network has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_activation
cls
echo ============================================================
echo   [6] Fixing Windows Activation...
echo ============================================================
echo.
net stop sppsvc 2>nul
net start sppsvc 2>nul
slmgr /rearm 2>nul
slmgr /xpr
slmgr /dlv
echo.
echo [OK] Activation fix attempted!
timeout /t 2 /nobreak >nul
exit /b

:fix_firewall
cls
echo ============================================================
echo   [7] Resetting Windows Firewall...
echo ============================================================
echo.
netsh advfirewall reset
netsh advfirewall set allprofiles state on
echo.
echo [OK] Windows Firewall has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_explorer
cls
echo ============================================================
echo   [8] Fixing Windows Explorer Crashes...
echo ============================================================
echo.
ie4uinit.exe -show 2>nul
del /a /q "%localappdata%\IconCache.db" 2>nul
del /a /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" 2>nul
taskkill /f /im explorer.exe 2>nul
timeout /t 2 /nobreak >nul
start explorer.exe
echo.
echo [OK] Explorer has been refreshed!
timeout /t 2 /nobreak >nul
exit /b

:clean_temp
cls
echo ============================================================
echo   [9] Cleaning Temporary Files...
echo ============================================================
echo.
echo Cleaning user temp files...
del /q /f /s "%TEMP%\*.*" 2>nul
echo Cleaning Windows temp files...
del /q /f /s "C:\Windows\Temp\*.*" 2>nul
echo Cleaning Prefetch...
del /q /f /s "C:\Windows\Prefetch\*.*" 2>nul
echo Cleaning Windows Update Cache...
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*.*" 2>nul
echo Cleaning Thumbnail Cache...
del /a /f /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache*" 2>nul
echo Cleaning Windows Error Reports...
del /q /f /s "%localappdata%\Microsoft\Windows\WER\ReportArchive\*.*" 2>nul
del /q /f /s "%localappdata%\Microsoft\Windows\WER\ReportQueue\*.*" 2>nul
echo Flushing DNS Cache...
ipconfig /flushdns 2>nul
echo Cleaning Delivery Optimization...
del /q /f /s "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*.*" 2>nul
echo.
echo [OK] Temporary files cleaned!
timeout /t 2 /nobreak >nul
exit /b

:fix_bsod
cls
echo ============================================================
echo   [a] Cleaning BSOD / Crash Dumps...
echo ============================================================
echo.
del /q /f /s "C:\Windows\Minidump\*.*" 2>nul
del /q /f /s "C:\Windows\LiveKernelReports\*.*" 2>nul
del /q /f /s "C:\Windows\MEMORY.DMP" 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v AutoReboot /t REG_DWORD /d 0 /f 2>nul
echo.
echo [OK] BSOD logs cleaned!
timeout /t 2 /nobreak >nul
exit /b

:fix_search
cls
echo ============================================================
echo   [b] Fixing Windows Search...
echo ============================================================
echo.
net stop WSearch 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows Search\CurrentVersionIndexer" /f 2>nul
net start WSearch 2>nul
echo.
echo [OK] Windows Search has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_grouppolicy
cls
echo ============================================================
echo   [c] Resetting Group Policy...
echo ============================================================
echo.
rd /s /q "%systemroot%\System32\GroupPolicy" 2>nul
rd /s /q "%systemroot%\System32\GroupPolicyUsers" 2>nul
gpupdate /force
echo.
echo [OK] Group Policy has been reset!
timeout /t 2 /nobreak >nul
exit /b

:fix_usb
cls
echo ============================================================
echo   [d] Fixing USB Issues...
echo ============================================================
echo.
net stop usbhub 2>nul
net start usbhub 2>nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f 2>nul
net stop "Device Install Service" 2>nul
net start "Device Install Service" 2>nul
net stop "Device Setup Manager" 2>nul
net start "Device Setup Manager" 2>nul
echo.
echo [OK] USB issues have been addressed!
timeout /t 2 /nobreak >nul
exit /b

:fix_diskcleanup
cls
echo ============================================================
echo   [e] Running Disk Cleanup...
echo ============================================================
echo.
echo Setting Disk Cleanup options...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Queue Bin" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Compress old files" /v StateFlags0001 /t REG_DWORD /d 2 /f 2>nul
echo.
echo Running Disk Cleanup...
cleanmgr /sagerun:1
echo.
echo [OK] Disk Cleanup completed!
timeout /t 2 /nobreak >nul
exit /b

:fix_all
cls
echo ============================================================
echo   [f] Running ALL Fixes...
echo ============================================================
echo.
call :fix_wupdate
call :fix_sfc
call :fix_dism
call :fix_store
call :fix_network
call :fix_firewall
call :fix_explorer
call :clean_temp
call :fix_bsod
call :fix_search
call :fix_grouppolicy
call :fix_usb
call :fix_diskcleanup
echo.
echo ============================================================
echo   [OK] ALL FIXES COMPLETED SUCCESSFULLY!
echo ============================================================
echo.
set /p restart="  Restart now? (Y/N): "
if /i "%restart%"=="Y" shutdown /r /t 10 /c "Restarting after MD Fix Commands..."
timeout /t 2 /nobreak >nul
exit /b
