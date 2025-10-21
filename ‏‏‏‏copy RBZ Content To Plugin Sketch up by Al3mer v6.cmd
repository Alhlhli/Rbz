@echo off

setlocal EnableDelayedExpansion

title ccopy RBZ Content To Plugin Sketch up by Al3mer v6

if not "%1"=="am_admin" (powershell start -Verb RunAs '%0' am_admin & exit /b)

echo ======================================
echo             copy RBZ Content To Plugin Sketch up by Al3mer v6
echo ======================================

:: ANSI color definitions
	set "RESET=[0m"
	set "GREEN=[92m"
	set "YELLOW=[93m"
	set "RED=[91m"
	set "CYAN=[96m"
	set "WHITE=[97m"

rem ========== Basic Variables ==========
set "SCRIPT_DIR=%~dp0"
set "PLUGINS_DIR=%SCRIPT_DIR%Plugins"
set "APPDATA_DIR=%APPDATA%\SketchUp"
set "PF1=%ProgramFiles%"
set "PF2=%ProgramFiles(x86)%"
set "HTML_REPORT=%SCRIPT_DIR%installation_report.html"

set /A extractedCount=0, failedCount=0
set "successfulPlugins="
set "failedPlugins="

rem ========== فحص توفر WMIC ==========
set "WMIC_AVAILABLE=false"
wmic OS Get Caption /value >nul 2>&1
if !errorlevel! equ 0 (
    set "WMIC_AVAILABLE=true"
    echo %GREEN%WMIC is available - using traditional method%RESET%
) else (
    echo %YELLOW%WMIC not available - using PowerShell alternative%RESET%
)

rem ========== System Information Collection ==========
 
set "COMPUTER_NAME=%COMPUTERNAME%"
set "USER_NAME=%USERNAME%"

rem ========== الحصول على التاريخ والوقت ==========
if "!WMIC_AVAILABLE!"=="true" (
    for /f "tokens=2 delims==" %%a in ('wmic OS Get LocalDateTime /value 2^>nul ^| find "="') do set "dt=%%a"
    if defined dt (
        set "CURRENT_DATE=!dt:~0,4!-!dt:~4,2!-!dt:~6,2!"
        set "CURRENT_TIME=!dt:~8,2!:!dt:~10,2!:!dt:~12,2!"
    )
) else (
    for /f "tokens=*" %%a in ('powershell -command "Get-Date -Format 'yyyy-MM-dd'"') do set "CURRENT_DATE=%%a"
    for /f "tokens=*" %%a in ('powershell -command "Get-Date -Format 'HH:mm:ss'"') do set "CURRENT_TIME=%%a"
)

rem ========== معلومات نظام التشغيل ==========
if "!WMIC_AVAILABLE!"=="true" (
    for /f "tokens=*" %%a in ('wmic os get Caption /value 2^>nul ^| find "="') do set "%%a"
    for /f "tokens=*" %%a in ('wmic os get Version /value 2^>nul ^| find "="') do set "%%a"
    for /f "tokens=*" %%a in ('wmic os get OSArchitecture /value 2^>nul ^| find "="') do set "%%a"
    for /f "tokens=2 delims==" %%a in ('wmic os get InstallDate /value 2^>nul ^| find "="') do set "win_install_raw=%%a"
    for /f "tokens=*" %%a in ('wmic cpu get Name /value 2^>nul ^| find "="') do set "%%a"
) else (
    for /f "tokens=*" %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_OperatingSystem).Caption"') do set "Caption=%%a"
    for /f "tokens=*" %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_OperatingSystem).Version"') do set "Version=%%a"
    for /f "tokens=*" %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture"') do set "OSArchitecture=%%a"
    for /f "tokens=*" %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_Processor).Name"') do set "Name=%%a"
    for /f "tokens=*" %%a in ('powershell -command "(Get-CimInstance -ClassName Win32_OperatingSystem).InstallDate.ToString('yyyyMMdd')"') do set "win_install_raw=%%a"
)

rem ========== تحديد تاريخ تثبيت ويندوز ==========
if defined win_install_raw (
    set "WIN_INSTALL_DATE=!win_install_raw:~0,4!-!win_install_raw:~4,2!-!win_install_raw:~6,2!"
) else (
    set "WIN_INSTALL_DATE=Unknown"
)

rem ========== حساب الذاكرة بدقة ==========
if "!WMIC_AVAILABLE!"=="true" (
    for /f "tokens=*" %%a in ('powershell -command "$cs = Get-CimInstance -ClassName Win32_ComputerSystem; $totalMemBytes = $cs.TotalPhysicalMemory; $totalGB = [math]::Round($totalMemBytes / 1GB, 1); Write-Output $totalGB"') do set "RAM_GB=%%a"
) else (
    for /f "tokens=*" %%a in ('powershell -command "$totalGB = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1); Write-Output $totalGB"') do set "RAM_GB=%%a"
)

rem ========== التأكد من وجود القيم الافتراضية ==========
if not defined Caption set "Caption=Windows"
if not defined Version set "Version=Unknown"
if not defined OSArchitecture set "OSArchitecture=Unknown"
if not defined Name set "Name=Unknown Processor"
if not defined RAM_GB set "RAM_GB=Unknown"

echo %CYAN%System Information:%RESET%
echo Computer Name: !COMPUTER_NAME!
echo User Name: !USER_NAME!
echo Date: !CURRENT_DATE! - !CURRENT_TIME!
echo OS: !Caption! (!OSArchitecture!)
echo OS Version: !Version!
echo Windows Installation: !WIN_INSTALL_DATE!
echo CPU: !Name!
echo Total RAM: !RAM_GB! GB



rem ========== اكتشاف إصدارات SketchUp المثبتة ==========
echo.
echo %CYAN%==== Detecting installed SketchUp versions ====%RESET%
set "versions="
set "version_paths="
set "plugins_paths="
set "sketchup_found=false"

for /L %%V in (2018,1,2030) do (
    set "pathApp=!APPDATA_DIR!\SketchUp %%V\SketchUp\Plugins"
    
    if exist "!pathApp!" (
        if exist "!PF1!\SketchUp\SketchUp %%V\SketchUp.exe" (
            echo %WHITE%- Found SketchUp %%V at "!PF1!\SketchUp\SketchUp %%V\SketchUp.exe"%RESET%
            call :add_version "%%V" "!PF1!\SketchUp\SketchUp %%V\SketchUp.exe" "!pathApp!"
            
        ) else if exist "!PF1!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe" (
            echo %WHITE%- Found SketchUp %%V at "!PF1!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe"%RESET%
            call :add_version "%%V" "!PF1!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe" "!pathApp!"
            
        ) else if exist "!PF2!\SketchUp\SketchUp %%V\SketchUp.exe" (
            echo %WHITE%- Found SketchUp %%V at "!PF2!\SketchUp\SketchUp %%V\SketchUp.exe"%RESET%
            call :add_version "%%V" "!PF2!\SketchUp\SketchUp %%V\SketchUp.exe" "!pathApp!"
            
        ) else if exist "!PF2!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe" (
            echo %WHITE%- Found SketchUp %%V at "!PF2!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe"%RESET%
            call :add_version "%%V" "!PF2!\SketchUp\SketchUp %%V\SketchUp\SketchUp.exe" "!pathApp!"
        )
    )
)

echo.
echo ================================================
if "!sketchup_found!"=="true" (
    echo %GREEN%       Detected versions:%RESET% !versions!
    echo %GREEN%       Plugins paths count: !plugins_paths_count!%RESET%
) else (
    echo %RED%No SketchUp versions were detected on this system!%RESET%
    goto :generate_no_sketchup_report
)
echo ================================================
echo.

timeout /t 3 >nul

rem ========== التحقق من وجود ملفات RBZ ==========
echo %CYAN%Checking for RBZ files...%RESET%
pushd "%SCRIPT_DIR%"
dir /B *.rbz >nul 2>&1
if errorlevel 1 (
    echo %RED%Error: No .rbz files found in the current directory.%RESET%
    pause
    exit /B 1
)
echo %GREEN%RBZ files found.%RESET%

rem ========== إنشاء مجلد الإخراج ==========
echo %CYAN%Creating temporary extraction folder...%RESET%
if not exist "%PLUGINS_DIR%" mkdir "%PLUGINS_DIR%"
echo %GREEN%Folder created: %PLUGINS_DIR%

rem ========== إزالة المسافات من أسماء الملفات ==========
echo.
echo %YELLOW%==== Removing spaces from RBZ filenames ====%RESET%
for %%F in (*.rbz) do (
    set "orig=%%~nF"
    set "fixed=!orig: =_!"
    if "!orig!" neq "!fixed!" (
        echo %WHITE%Renaming "%%F" to "!fixed!.rbz"%RESET%
        ren "%%F" "!fixed!.rbz"
    )
)
echo %GREEN%Filename normalization done.%RESET%

rem ========== استخراج المحتوى إلى مجلد Plugins مؤقت ==========
echo.
echo %YELLOW%==== Extracting plugins ====%RESET%
for /F "delims=" %%F in ('dir /B *.rbz') do (
    echo %WHITE%Extracting "%%F" ...%RESET%
    tar -xf "%%F" -C "%PLUGINS_DIR%" >nul 2>&1
    if errorlevel 1 (
        echo %RED%[!] Extraction failed: %%~nF%RESET%
        set /A failedCount+=1
        set "failedPlugins=!failedPlugins!%%~nF,"
    ) else (
        echo %GREEN%[+] Successfully extracted: %%~nF%RESET%
        set /A extractedCount+=1
        set "successfulPlugins=!successfulPlugins!%%~nF,"
    )
)
echo %GREEN%Extraction complete:%RESET% Extracted %extractedCount% plugins, %RED%Failed %failedCount%%RESET%

rem ========== نسخ الإضافات إلى مجلد Plugins لكل إصدار متوافق ==========
echo.
echo %YELLOW%==== Copying plugins to detected SketchUp folders ====%RESET%

rem Split plugins_paths and copy to each
set "temp_paths=!plugins_paths!"
:copy_loop
for /f "tokens=1* delims=|" %%a in ("!temp_paths!") do (
    set "current_path=%%a"
    set "temp_paths=%%b"
    
    echo %WHITE%Copying to "!current_path!" ...%RESET%
    if exist "!current_path!" (
        xcopy /S /E /Y "%PLUGINS_DIR%\*" "!current_path!\" >nul 2>&1
        if errorlevel 1 (
            echo %RED%[!] Failed to copy to "!current_path!".%RESET%
        ) else (
            echo %GREEN%[+] Successfully copied to "!current_path!".%RESET%
        )
    ) else (
        echo %YELLOW%[!] Path does not exist: "!current_path!"%RESET%
    )
    
    if defined temp_paths goto copy_loop
)

echo %GREEN%Copy operations complete.%RESET%

rem ========== تحضير قوائم الإضافات ==========
set "succList=!successfulPlugins:,= !"
set "failList=!failedPlugins:,= !"

REM تحضير قوائم الإضافات على شكل عناصر HTML
set "successfulPluginsList="
for %%P in (!succList!) do set "successfulPluginsList=!successfulPluginsList!^<li^>%%~P^</li^>"

set "failedPluginsList="
for %%P in (!failList!) do set "failedPluginsList=!failedPluginsList!^<li^>%%~P^</li^>"


set "failedPluginsList="
for %%P in (!failList!) do (
    if defined failedPluginsList (
        set "failedPluginsList=!failedPluginsList!^<li^>%%~P^</li^>"
    ) else (
        set "failedPluginsList=^<li^>%%~P^</li^>"
    )
)

rem ========== تحضير جدول الإصدارات ==========
call :prepare_version_table


rem ========== توليد تقرير HTML نهائي ==========
echo.
echo %YELLOW%==== Generating HTML report ====%RESET%
call :generate_html_report

echo %GREEN%HTML report generated: %HTML_REPORT%%RESET%
timeout /t 2 >nul


start "" "%HTML_REPORT%"
echo %GREEN%Error report opened.%RESET%


rem ========== تنظيف الملفات المؤقتة ==========
if exist "%PLUGINS_DIR%" rd /S /Q "%PLUGINS_DIR%" 2>nul

popd
endlocal
exit /B 0

rem ========== دالة إضافة إصدار ==========
:add_version
set "ver_to_add=%~1"
set "path_to_add=%~2"
set "plugin_path_to_add=%~3"

if "!sketchup_found!"=="false" (
    set "versions=!ver_to_add!"
    set "version_paths=!path_to_add!"
    set "plugins_paths=!plugin_path_to_add!"
    set "plugins_paths_count=1"
) else (
    set "versions=!versions! !ver_to_add!"
    set "version_paths=!version_paths!|!path_to_add!"
    set "plugins_paths=!plugins_paths!|!plugin_path_to_add!"
    set /A plugins_paths_count+=1
)
set "sketchup_found=true"
goto :eof

rem ========== دالة تحضير جدول الإصدارات ==========
:prepare_version_table
set "versionTableRows="

rem Split versions into array
set "temp_versions=!versions!"
set "temp_plugins=!plugins_paths!"
set "idx=0"

:version_loop
for /f "tokens=1* delims= " %%a in ("!temp_versions!") do (
    set /A idx+=1
    set "current_ver=%%a"
    set "temp_versions=%%b"
    
    rem Get corresponding plugin path
    for /f "tokens=1* delims=|" %%c in ("!temp_plugins!") do (
        set "current_plugin_path=%%c"
        set "temp_plugins=%%d"
    )
    
    rem تحويل المسار لـ file protocol
    set "file_url=file:///!current_plugin_path:\=/!"
    
    rem Add to table with direct file URL
    if defined versionTableRows (
        set "versionTableRows=!versionTableRows!^<tr^>^<td^>!current_ver!^</td^>^<td class='path-cell'^>!current_plugin_path!^</td^>^<td^>^<a href='!file_url!' target='_blank' class='btn' style='width:auto;padding:5px 10px;font-size:12px;'^>Open Folder^</a^>^</td^>^</tr^>"
    ) else (
        set "versionTableRows=^<tr^>^<td^>!current_ver!^</td^>^<td class='path-class'^>!current_plugin_path!^</td^>^<td^>^<a href='!file_url!' target='_blank' class='btn' style='width:auto;padding:5px 10px;font-size:12px;'^>Open Folder^</a^>^</td^>^</tr^>"
    )
    
    if defined temp_versions goto version_loop_direct
)
goto :eof

rem ========== دالة توليد تقرير HTML ==========
:generate_html_report
(
echo ^<!DOCTYPE html^>
echo ^<html lang="ar" dir="rtl"^>
echo ^<head^>
echo   ^<meta charset="UTF-8"^>
echo   ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo   ^<title^>تقرير تثبيت إضافات SketchUp^</title^>
echo ^<style^>
echo   :root {
echo     --primary-color: #2c3e50;
echo     --accent-color: #27ae60;
echo     --error-color: #e74c3c;
echo     --warning-color: #f39c12;
echo     --info-color: #3498db;
echo     --background-color: #f5f7fa;
echo     --card-color: #ffffff;
echo     --text-color: #333333;
echo     --border-radius: 10px;
echo     --box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.1^);
echo     --transition-speed: 0.3s;
echo     --hover-transform: translateY^(-2px^);
echo   }
echo   * {
echo     margin: 0;
echo     padding: 0;
echo     box-sizing: border-box;
echo     font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
echo   }
echo   body {
echo     background-color: var^(--background-color^);
echo     color: var^(--text-color^);
echo     margin: 0;
echo     padding: 20px;
echo     line-height: 1.6;
echo     direction: rtl;
echo   }
echo   .container {
echo     max-width: 1200px;
echo     margin: 0 auto;
echo     padding: 20px;
echo   }
echo   header {
echo     background: linear-gradient^(135deg, var^(--primary-color^), #34495e^);
echo     color: white;
echo     padding: 25px;
echo     border-radius: var^(--border-radius^);
echo     text-align: center;
echo     margin-bottom: 30px;
echo     box-shadow: var^(--box-shadow^);
echo   }
echo   h1, h2, h3 {
echo     margin-bottom: 16px;
echo   }
echo   .card {
echo     background-color: var^(--card-color^);
echo     border-radius: var^(--border-radius^);
echo     padding: 20px;
echo     margin-bottom: 20px;
echo     box-shadow: var^(--box-shadow^);
echo     transition: transform var^(--transition-speed^), box-shadow var^(--transition-speed^);
echo   }
echo   .card:hover {
echo     transform: var^(--hover-transform^);
echo     box-shadow: 0 8px 16px rgba^(0, 0, 0, 0.15^);
echo   }
echo   .status-box {
echo     text-align: center;
echo     padding: 15px;
echo     border-radius: var^(--border-radius^);
echo     margin-bottom: 20px;
echo     font-weight: bold;
echo     font-size: 20px;
echo   }
echo   .success {
echo     background: linear-gradient^(135deg, rgba^(39, 174, 96, 0.2^), rgba^(39, 174, 96, 0.1^)^);
echo     color: #27ae60;
echo     border: 2px solid #27ae60;
echo   }
echo   .versions {
echo     background: linear-gradient^(135deg, rgba^(41, 128, 185, 0.2^), rgba^(41, 128, 185, 0.1^)^);
echo     color: #2980b9;
echo     border: 2px solid #2980b9;
echo   }
echo   .plugin-lists {
echo     display: flex;
echo     flex-wrap: wrap;
echo     gap: 20px;
echo     margin-bottom: 30px;
echo   }
echo   .plugin-list {
echo     flex: 1;
echo     min-width: 300px;
echo   }
echo   .plugin-count {
echo     display: inline-block;
echo     background-color: var^(--primary-color^);
echo     color: white;
echo     border-radius: 50%%;
echo     width: 35px;
echo     height: 35px;
echo     text-align: center;
echo     line-height: 35px;
echo     font-weight: bold;
echo     box-shadow: 0 2px 4px rgba^(0, 0, 0, 0.2^);
echo   }
echo   .success-count {
echo     background: linear-gradient^(135deg, var^(--accent-color^), #229954^);
echo   }
echo   .error-count {
echo     background: linear-gradient^(135deg, var^(--error-color^), #c0392b^);
echo   }
echo   ul {
echo     list-style-position: inside;
echo     margin-right: 20px;
echo   }
echo   li {
echo     padding: 8px 0;
echo     border-bottom: 1px dashed #eaeaea;
echo     transition: background-color var^(--transition-speed^);
echo   }
echo   li:hover {
echo     background-color: #f8f9fa;
echo     padding-right: 5px;
echo   }
echo   .tab {
echo     overflow: hidden;
echo     border: 1px solid #ccc;
echo     background: linear-gradient^(to bottom, #f1f1f1, #e9e9e9^);
echo     border-radius: var^(--border-radius^) var^(--border-radius^) 0 0;
echo   }
echo   .tab button {
echo     background-color: inherit;
echo     float: right;
echo     border: none;
echo     outline: none;
echo     cursor: pointer;
echo     padding: 14px 20px;
echo     transition: all var^(--transition-speed^);
echo     font-size: 16px;
echo     font-weight: 500;
echo   }
echo   .tab button:hover {
echo     background-color: #ddd;
echo     transform: translateY^(-1px^);
echo   }
echo   .tab button.active {
echo     background: linear-gradient^(135deg, var^(--primary-color^), #34495e^);
echo     color: white;
echo     box-shadow: inset 0 2px 4px rgba^(0, 0, 0, 0.2^);
echo   }
echo   .tabcontent {
echo     display: none;
echo     padding: 25px;
echo     border: 1px solid #ccc;
echo     border-top: none;
echo     border-radius: 0 0 var^(--border-radius^) var^(--border-radius^);
echo     background-color: var^(--card-color^);
echo     animation: fadeEffect 0.5s ease-in;
echo   }
echo   @keyframes fadeEffect {
echo     from { opacity: 0; transform: translateY^(10px^); }
echo     to { opacity: 1; transform: translateY^(0^); }
echo   }
echo   .table-container {
echo     overflow-x: auto;
echo     margin: 20px 0;
echo     border-radius: var^(--border-radius^);
echo     box-shadow: var^(--box-shadow^);
echo     background: white;
echo   }
echo   table {
echo     width: 100%%;
echo     border-collapse: collapse;
echo   }
echo   th, td {
echo     padding: 15px 12px;
echo     text-align: center;
echo     border-bottom: 1px solid #eaeaea;
echo   }
echo   th {
echo     background: linear-gradient^(135deg, var^(--primary-color^), #34495e^);
echo     color: white;
echo     font-weight: 600;
echo     position: sticky;
echo     top: 0;
echo     z-index: 10;
echo   }
echo   tr:nth-child^(even^) {
echo     background-color: #f8f9fa;
echo   }
echo   tr:hover {
echo     background-color: #e3f2fd;
echo     transition: background-color var^(--transition-speed^);
echo   }
echo   .path-container {
echo     display: flex;
echo     align-items: center;
echo     gap: 8px;
echo     width: 100%%;
echo     max-width: 400px;
echo   }
echo   .path-input {
echo     flex: 1;
echo     padding: 8px 12px;
echo     border: 2px solid #e0e0e0;
echo     border-radius: 6px;
echo     background: #f9f9f9;
echo     font-family: 'Consolas', 'Courier New', monospace;
echo     font-size: 12px;
echo     cursor: text;
echo     transition: all var^(--transition-speed^);
echo     min-width: 200px;
echo   }
echo   .path-input:focus {
echo     outline: none;
echo     border-color: var^(--info-color^);
echo     background: white;
echo     box-shadow: 0 0 0 3px rgba^(52, 152, 219, 0.1^);
echo   }
echo   .copy-btn {
echo     padding: 8px 12px;
echo     background: linear-gradient^(135deg, var^(--info-color^), #2980b9^);
echo     color: white;
echo     border: none;
echo     border-radius: 6px;
echo     cursor: pointer;
echo     font-size: 14px;
echo     min-width: 40px;
echo     transition: all var^(--transition-speed^);
echo     display: flex;
echo     align-items: center;
echo     justify-content: center;
echo   }
echo   .copy-btn:hover {
echo     background: linear-gradient^(135deg, #2980b9, #1f5f8b^);
echo     transform: translateY^(-1px^);
echo     box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.2^);
echo   }
echo   .copy-btn:active {
echo     transform: translateY^(0^);
echo   }
echo   .copy-btn.success {
echo     background: linear-gradient^(135deg, var^(--accent-color^), #229954^);
echo   }
echo   .open-btn {
echo     background: linear-gradient^(135deg, var^(--accent-color^), #229954^);
echo     border: none;
echo     color: white;
echo     padding: 10px 16px;
echo     border-radius: 6px;
echo     cursor: pointer;
echo     font-size: 13px;
echo     font-weight: 500;
echo     transition: all var^(--transition-speed^);
echo     display: inline-flex;
echo     align-items: center;
echo     gap: 5px;
echo   }
echo   .open-btn:hover {
echo     background: linear-gradient^(135deg, #229954, #1e7e34^);
echo     transform: translateY^(-1px^);
echo     box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.2^);
echo   }
echo   .open-btn:before {
echo     content: '📁';
echo     margin-left: 3px;
echo   }
echo   .path-cell {
echo     min-width: 350px;
echo     max-width: 500px;
echo   }
echo   .btn {
echo     padding: 8px 16px;
echo     background: linear-gradient^(135deg, var^(--primary-color^), #34495e^);
echo     color: white;
echo     text-decoration: none;
echo     border-radius: 6px;
echo     font-size: 13px;
echo     font-weight: 500;
echo     border: none;
echo     cursor: pointer;
echo     transition: all var^(--transition-speed^);
echo     display: inline-block;
echo   }
echo   .btn:hover {
echo     background: linear-gradient^(135deg, #34495e, #2c3e50^);
echo     transform: translateY^(-1px^);
echo     box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.2^);
echo   }
echo   .system-info-grid {
echo     display: grid;
echo     grid-template-columns: repeat^(auto-fit, minmax^(320px, 1fr^)^);
echo     gap: 20px;
echo   }
echo   .info-card {
echo     border: 2px solid #eaeaea;
echo     border-radius: var^(--border-radius^);
echo     padding: 20px;
echo     background: white;
echo     transition: all var^(--transition-speed^);
echo   }
echo   .info-card:hover {
echo     border-color: var^(--primary-color^);
echo     transform: var^(--hover-transform^);
echo     box-shadow: var^(--box-shadow^);
echo   }
echo   .info-card h4 {
echo     margin-bottom: 15px;
echo     color: var^(--primary-color^);
echo     border-bottom: 2px solid var^(--primary-color^);
echo     padding-bottom: 8px;
echo     font-weight: 600;
echo   }
echo   .contact-info {
echo     display: grid;
echo     grid-template-columns: 1fr;
echo     gap: 25px;
echo   }
echo   .contact-card {
echo     background-color: var^(--card-color^);
echo     border-radius: var^(--border-radius^);
echo     overflow: hidden;
echo     box-shadow: var^(--box-shadow^);
echo     transition: all var^(--transition-speed^);
echo   }
echo   .contact-card:hover {
echo     transform: var^(--hover-transform^);
echo     box-shadow: 0 8px 16px rgba^(0, 0, 0, 0.15^);
echo   }
echo   .contact-header {
echo     background: linear-gradient^(135deg, var^(--primary-color^), #34495e^);
echo     color: white;
echo     padding: 20px;
echo     text-align: center;
echo     font-weight: bold;
echo     font-size: 16px;
echo   }
echo   .contact-links {
echo     padding: 20px;
echo   }
echo   .contact-link {
echo     display: block;
echo     padding: 12px 20px;
echo     margin: 8px 0;
echo     border-radius: var^(--border-radius^);
echo     background: linear-gradient^(135deg, #f8f9fa, #e9ecef^);
echo     color: var^(--primary-color^);
echo     text-decoration: none;
echo     transition: all var^(--transition-speed^);
echo     text-align: center;
echo     font-weight: 500;
echo   }
echo   .contact-link:hover {
echo     background: linear-gradient^(135deg, #e9ecef, #dee2e6^);
echo     transform: translateY^(-1px^);
echo     box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.1^);
echo   }
echo   .notification {
echo     position: fixed;
echo     top: 20px;
echo     left: 50%%;
echo     transform: translateX^(-50%%^);
echo     padding: 15px 25px;
echo     border-radius: var^(--border-radius^);
echo     color: white;
echo     font-weight: 500;
echo     z-index: 1000;
echo     opacity: 0;
echo     transition: all var^(--transition-speed^);
echo     pointer-events: none;
echo   }
echo   .notification.show {
echo     opacity: 1;
echo     transform: translateX^(-50%%^) translateY^(10px^);
echo   }
echo   .notification.success {
echo     background: linear-gradient^(135deg, var^(--accent-color^), #229954^);
echo   }
echo   .notification.error {
echo     background: linear-gradient^(135deg, var^(--error-color^), #c0392b^);
echo   }
echo   footer {
echo     text-align: center;
echo     margin-top: 40px;
echo     color: #7f8c8d;
echo     font-size: 14px;
echo     padding: 20px;
echo     border-top: 1px solid #eaeaea;
echo   }
echo   @media ^(max-width: 768px^) {
echo     .container {
echo       padding: 10px;
echo     }
echo     .plugin-lists {
echo       flex-direction: column;
echo     }
echo     .tab button {
echo       font-size: 14px;
echo       padding: 12px 16px;
echo     }
echo     .path-container {
echo       flex-direction: column;
echo       gap: 5px;
echo     }
echo     .path-input {
echo       min-width: auto;
echo       width: 100%%;
echo     }
echo     th, td {
echo       padding: 10px 8px;
echo       font-size: 12px;
echo     }
echo   }
echo ^</style^>
echo ^</head^>
echo ^<body^>
echo   ^<div class="container"^>
echo     ^<header^>
echo       ^<h1^>تقرير تثبيت إضافات SketchUp^</h1^>
echo       ^<p^>تم إكمال عملية الاستخراج والنسخ التلقائي للإضافات^</p^>
echo       ^<p style="font-size: 14px; margin-top: 10px;"^>!CURRENT_DATE! - !CURRENT_TIME!^</p^>
echo     ^</header^>
echo.
echo     ^<div class="tab"^>
echo       ^<button class="tablinks active" onclick="openTab(event, 'InstallStatus')"^>حالة التثبيت^</button^>
echo       ^<button class="tablinks" onclick="openTab(event, 'SketchUpVersions')"^>إصدارات SketchUp^</button^>
echo       ^<button class="tablinks" onclick="openTab(event, 'SystemInfo')"^>معلومات النظام^</button^>
echo       ^<button class="tablinks" onclick="openTab(event, 'Contact')"^>اتصل بنا^</button^>
echo     ^</div^>
echo.
echo     ^<div id="InstallStatus" class="tabcontent" style="display: block;"^>
echo       ^<div class="card versions"^>
echo         ^<div class="status-box versions"^>
echo           ^<span^>إصدارات SketchUp المكتشفة: !versions!^</span^>
echo         ^</div^>
echo       ^</div^>
echo.
echo       ^<div class="card"^>
echo         ^<div class="status-box success"^>
echo           ^<span^>✓ تم التثبيت بنجاح^</span^>
echo         ^</div^>
echo         ^<p style="text-align: center; font-size: 18px;"^>تمت عملية الاستخراج والنسخ التلقائي للإضافات بنجاح^</p^>
echo       ^</div^>
echo.
echo       ^<div class="plugin-lists"^>
echo         ^<div class="plugin-list card"^>
echo           ^<h3^>^<span class="plugin-count success-count"^>!extractedCount!^</span^> الإضافات التي تم معالجتها بنجاح^</h3^>
echo           ^<ul^>!successfulPluginsList!^</ul^>
echo         ^</div^>
echo         ^<div class="plugin-list card"^>
echo           ^<h3^>^<span class="plugin-count error-count"^>!failedCount!^</span^> الإضافات التي فشلت معالجتها^</h3^>
echo           ^<ul^>!failedPluginsList!^</ul^>
echo         ^</div^>
echo       ^</div^>
echo     ^</div^>
echo.
echo ^<div id="SketchUpVersions" class="tabcontent"^>
echo   ^<div class="card"^>
echo     ^<h2^>مسارات إضافات SketchUp^</h2^>
echo     ^<p^>أماكن حفظ الإضافات المثبتة:^</p^>
echo     ^<div class="table-container"^>
echo       ^<table^>
echo         ^<thead^>
echo           ^<tr^>
echo             ^<th^>الإصدار^</th^>
echo             ^<th^>مسار الإضافات^</th^>
echo             ^<th^>عرض المجلد^</th^>
echo           ^</tr^>
echo         ^</thead^>
echo         ^<tbody^>
echo           !versionTableRows!
echo         ^</tbody^>
echo       ^</table^>
echo     ^</div^>
echo   ^</div^>
echo ^</div^>
echo.
echo     ^<div id="SystemInfo" class="tabcontent"^>
echo       ^<div class="card"^>
echo         ^<h2^>معلومات النظام والحاسوب^</h2^>
echo         ^<div class="system-info-grid"^>
echo           ^<div class="info-card"^>
echo             ^<h4^>معلومات الحاسوب^</h4^>
echo             ^<p^>^<strong^>اسم الحاسوب:^</strong^> !COMPUTER_NAME!^</p^>
echo             ^<p^>^<strong^>اسم المستخدم:^</strong^> !USER_NAME!^</p^>
echo           ^</div^>
echo           ^<div class="info-card"^>
echo             ^<h4^>نظام التشغيل^</h4^>
echo             ^<p^>^<strong^>الإصدار:^</strong^> !Caption!^</p^>
echo             ^<p^>^<strong^>رقم الإصدار:^</strong^> !Version!^</p^>
echo             ^<p^>^<strong^>البنية:^</strong^> !OSArchitecture!^</p^>
echo           ^</div^>
echo           ^<div class="info-card"^>
echo             ^<h4^>المعالج والذاكرة^</h4^>
echo             ^<p^>^<strong^>المعالج:^</strong^> !Name!^</p^>
echo             ^<p^>^<strong^>الذاكرة:^</strong^> !RAM_GB! GB^</p^>
echo           ^</div^>
echo         ^</div^>
echo.
echo       ^</div^>
echo     ^</div^>
echo.
echo     ^<div id="Contact" class="tabcontent"^>
echo       ^<div class="contact-info"^>
echo         ^<div class="contact-card"^>
echo           ^<div class="contact-header"^>
echo             م/ عامر الحلحلي - Arch/ Amer Al-hlhli
echo           ^</div^>
echo           ^<div class="contact-links"^>
echo             ^<a href="https://t.me/pro3mer" target="_blank" class="contact-link"^>برامج هندسية - Engineering programs^</a^>
echo             ^<a href="https://t.me/apk3mer" target="_blank" class="contact-link"^>تطبيقات اندرويد مفعلة - Activated Android applications^</a^>
echo             ^<a href="https://t.me/ppt3mer" target="_blank" class="contact-link"^>ملفات باوربوينت مميزة - Distinctive PowerPoint files^</a^>
echo             ^<a href="https://www.youtube.com/@hlhli?sub_confirmation=1" target="_blank" class="contact-link"^>قناة اليوتيوب - YouTube channel^</a^>
echo           ^</div^>
echo         ^</div^>
echo       ^</div^>
echo     ^</div^>
echo.
echo     ^<footer^>
echo       ^<p^>تم إنشاء هذا التقرير تلقائيًا بواسطة سكربت تثبيت إضافات SketchUp^</p^>
echo     ^</footer^>
echo   ^</div^>
echo.
echo   ^<script^>
echo     function openTab^(evt, tabName^) {
echo       var i, tabcontent, tablinks;
echo       tabcontent = document.getElementsByClassName^("tabcontent"^);
echo       for ^(i = 0; i ^< tabcontent.length; i++^) {
echo         tabcontent[i].style.display = "none";
echo       }
echo       tablinks = document.getElementsByClassName^("tablinks"^);
echo       for ^(i = 0; i ^< tablinks.length; i++^) {
echo         tablinks[i].className = tablinks[i].className.replace^(" active", ""^);
echo       }
echo       document.getElementById^(tabName^).style.display = "block";
echo       evt.currentTarget.className += " active";
echo     }
echo     // Function to calculate days ago
echo     function daysAgo^(dateStr^) {
echo       if ^(dateStr === 'Unknown'^) return 'Unknown';
echo       const parts = dateStr.split^('-'^);
echo       const date = new Date^(parts[0], parts[1]-1, parts[2]^);
echo       const today = new Date^(^);
echo       const diffTime = Math.abs^(today - date^);
echo       const diffDays = Math.ceil^(diffTime / ^(1000 * 60 * 60 * 24^)^);
echo       return diffDays + ' يوم';
echo     }
echo     // Function to try opening SketchUp
echo     function openSketchUp^(path^) {
echo       try {
echo         const fileProtocolPath = 'file:///' + path;
echo         const confirmed = confirm^('هل ترغب في فتح برنامج SketchUp؟'^);
echo         if ^(confirmed^) {
echo           window.open^(fileProtocolPath, '_blank'^);
echo         }
echo         return false; // Prevent default link behavior
echo       } catch ^(err^) {
echo         console.error^('Error opening SketchUp:', err^);
echo         return false;
echo       }
echo     }
echo     // Add days ago information to the installed versions table
echo     window.onload = function^(^) {
echo       const table = document.querySelector^('table'^);
echo       if ^(table^) {
echo         const rows = table.querySelectorAll^('tbody tr'^);
echo         rows.forEach^(function^(row^) {
echo           const cells = row.querySelectorAll^('td'^);
echo           if ^(cells.length ^>= 3^) {
echo             const installDate = cells[2].textContent;
echo             const lastRunDate = cells[3].textContent;
echo             if ^(installDate !== 'Unknown'^) {
echo               cells[2].innerHTML = installDate + ' ^<span style="color:#666;font-size:0.8em"^>^(' + daysAgo^(installDate^) + ' مضت^)^</span^>';
echo             }
echo             if ^(lastRunDate !== 'Unknown'^) {
echo               cells[3].innerHTML = lastRunDate + ' ^<span style="color:#666;font-size:0.8em"^>^(' + daysAgo^(lastRunDate^) + ' مضت^)^</span^>';
echo             }
echo           }
echo         }^);
echo       }
echo     };
echo   ^</script^>
echo ^</body^>
echo ^</html^>
) > "%HTML_REPORT%"



REM ==================== تنظيف الملفات المؤقتة ====================
rd /S /Q "%PLUGINS_DIR%" 2>nul
popd
endlocal
exit /B 0

:generate_no_sketchup_report
echo.
echo %RED%== No SketchUp installation found! Creating error report... ==%RESET%

(
echo ^<!DOCTYPE html^>
echo ^<html lang="ar" dir="rtl"^>
echo ^<head^>
echo   ^<meta charset="UTF-8"^>
echo   ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo   ^<title^>تقرير تثبيت الإضافات - خطأ^</title^>
echo   ^<style^>
echo     :root {
echo       --primary-color: #2c3e50;
echo       --accent-color: #27ae60;
echo       --error-color: #e74c3c;
echo       --background-color: #f5f7fa;
echo       --card-color: #ffffff;
echo       --text-color: #333333;
echo       --border-radius: 10px;
echo       --box-shadow: 0 4px 8px rgba^(0, 0, 0, 0.1^);
echo       --transition-speed: 0.3s;
echo     }
echo     * {
echo       margin: 0;
echo       padding: 0;
echo       box-sizing: border-box;
echo       font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
echo     }
echo     body {
echo       background-color: var^(--background-color^);
echo       color: var^(--text-color^);
echo       margin: 0;
echo       padding: 20px;
echo       line-height: 1.6;
echo     }
echo     .container {
echo       max-width: 1000px;
echo       margin: 0 auto;
echo       padding: 20px;
echo     }
echo     header {
echo       background-color: var^(--primary-color^);
echo       color: white;
echo       padding: 20px;
echo       border-radius: var^(--border-radius^);
echo       text-align: center;
echo       margin-bottom: 30px;
echo       box-shadow: var^(--box-shadow^);
echo     }
echo     h1, h2, h3 {
echo       margin-bottom: 16px;
echo     }
echo     .card {
echo       background-color: var^(--card-color^);
echo       border-radius: var^(--border-radius^);
echo       padding: 20px;
echo       margin-bottom: 20px;
echo       box-shadow: var^(--box-shadow^);
echo       transition: transform var^(--transition-speed^);
echo     }
echo     .card:hover {
echo       transform: translateY^(-5px^);
echo     }
echo     .status-box {
echo       text-align: center;
echo       padding: 15px;
echo       border-radius: var^(--border-radius^);
echo       margin-bottom: 20px;
echo       font-weight: bold;
echo       font-size: 20px;
echo     }
echo     .error {
echo       background-color: rgba^(231, 76, 60, 0.2^);
echo       color: #e74c3c;
echo       border: 2px solid #e74c3c;
echo     }
echo     .error-icon {
echo       font-size: 72px;
echo       color: #e74c3c;
echo       text-align: center;
echo       margin: 20px 0;
echo     }
echo     .error-message {
echo       font-size: 20px;
echo       text-align: center;
echo       margin-bottom: 30px;
echo     }
echo     .solution {
echo       font-size: 18px;
echo       padding: 20px;
echo       background-color: rgba^(41, 128, 185, 0.1^);
echo       border-radius: var^(--border-radius^);
echo       margin-bottom: 30px;
echo     }
echo     .solution h3 {
echo       color: #2980b9;
echo     }
echo     .contact-info {
echo       display: grid;
echo       grid-template-columns: repeat^(auto-fit, minmax^(300px, 1fr^)^);
echo       gap: 20px;
echo       margin-top: 24px;
echo     }
echo     .contact-card {
echo       background-color: var^(--card-color^);
echo       border-radius: var^(--border-radius^);
echo       overflow: hidden;
echo       box-shadow: var^(--box-shadow^);
echo       transition: transform var^(--transition-speed^);
echo     }
echo     .contact-card:hover {
echo       transform: translateY^(-5px^);
echo     }
echo     .contact-header {
echo       background-color: var^(--primary-color^);
echo       color: white;
echo       padding: 15px;
echo       text-align: center;
echo       font-weight: bold;
echo     }
echo     .contact-links {
echo       padding: 15px;
echo     }
echo     .contact-link {
echo       display: block;
echo       padding: 10px 15px;
echo       margin: 5px 0;
echo       border-radius: var^(--border-radius^);
echo       background-color: #f8f9fa;
echo       color: var^(--primary-color^);
echo       text-decoration: none;
echo       transition: background-color var^(--transition-speed^);
echo       text-align: center;
echo     }
echo     .contact-link:hover {
echo       background-color: #e9ecef;
echo     }
echo     .btn {
echo       display: block;
echo       width: 80%%;
echo       max-width: 300px;
echo       margin: 0 auto;
echo       padding: 12px 24px;
echo       background-color: var^(--primary-color^);
echo       color: white;
echo       text-align: center;
echo       text-decoration: none;
echo       border-radius: var^(--border-radius^);
echo       font-weight: bold;
echo       transition: background-color var^(--transition-speed^);
echo     }
echo     .btn:hover {
echo       background-color: #1a2533;
echo     }
echo     footer {
echo       text-align: center;
echo       margin-top: 30px;
echo       color: #7f8c8d;
echo       font-size: 14px;
echo     }
echo     /* Additional Styles */
echo     .tab {
echo       overflow: hidden;
echo       border: 1px solid #ccc;
echo       background-color: #f1f1f1;
echo       border-radius: var^(--border-radius^) var^(--border-radius^) 0 0;
echo     }
echo     .tab button {
echo       background-color: inherit;
echo       float: right;
echo       border: none;
echo       outline: none;
echo       cursor: pointer;
echo       padding: 14px 16px;
echo       transition: 0.3s;
echo       font-size: 17px;
echo     }
echo     .tab button:hover {
echo       background-color: #ddd;
echo     }
echo     .tab button.active {
echo       background-color: var^(--primary-color^);
echo       color: white;
echo     }
echo     .tabcontent {
echo       display: none;
echo       padding: 20px;
echo       border: 1px solid #ccc;
echo       border-top: none;
echo       border-radius: 0 0 var^(--border-radius^) var^(--border-radius^);
echo       animation: fadeEffect 1s;
echo     }
echo     @keyframes fadeEffect {
echo       from {opacity: 0;}
echo       to {opacity: 1;}
echo     }
echo     .system-info-grid {
echo       display: grid;
echo       grid-template-columns: repeat^(auto-fit, minmax^(300px, 1fr^)^);
echo       gap: 15px;
echo     }
echo     .info-card {
echo       border: 1px solid #eaeaea;
echo       border-radius: var^(--border-radius^);
echo       padding: 15px;
echo     }
echo     .info-card h4 {
echo       margin-bottom: 10px;
echo       color: var^(--primary-color^);
echo       border-bottom: 1px solid #eaeaea;
echo       padding-bottom: 5px;
echo     }
echo     .highlight {
echo       background-color: #fff3cd;
echo       padding: 2px 5px;
echo       border-radius: 3px;
echo       font-weight: bold;
echo     }
echo   ^</style^>
echo ^</head^>
echo ^<body^>
echo   ^<div class="container"^>
echo     ^<header^>
echo       ^<h1^>تقرير تثبيت إضافات SketchUp - خطأ^</h1^>
echo       ^<p^>تعذر إكمال عملية تثبيت الإضافات^</p^>
echo       ^<p style="font-size: 14px; margin-top: 10px;"^>!CURRENT_DATE! - !CURRENT_TIME!^</p^>
echo     ^</header^>
echo.
echo     ^<div class="tab"^>
echo       ^<button class="tablinks active" onclick="openTab(event, 'Error')"^>الخطأ^</button^>
echo       ^<button class="tablinks" onclick="openTab(event, 'SystemInfo')"^>معلومات النظام^</button^>
echo       ^<button class="tablinks" onclick="openTab(event, 'Contact')"^>اتصل بنا^</button^>
echo     ^</div^>
echo.
echo     ^<div id="Error" class="tabcontent" style="display: block;"^>
echo       ^<div class="card"^>
echo         ^<div class="status-box error"^>
echo           ^<span^>⚠️ لم يتم العثور على نسخة SketchUp مثبتة!^</span^>
echo         ^</div^>
echo         ^<div class="error-icon"^>❌^</div^>
echo         ^<p class="error-message"^>لم يتم العثور على أي نسخة مثبتة من برنامج SketchUp على جهازك.^<br^>لا يمكن تثبيت الإضافات بدون وجود البرنامج الرئيسي.^</p^>
echo         ^<div class="solution"^>
echo           ^<h3^>الحل:^</h3^>
echo           ^<p^>1. قم بتثبيت برنامج SketchUp على جهازك أولاً.^</p^>
echo           ^<p^>2. تأكد من تثبيته بشكل صحيح وتشغيله مرة واحدة على الأقل.^</p^>
echo           ^<p^>3. قم بتشغيل هذا السكربت مرة أخرى لتثبيت الإضافات.^</p^>
echo         ^</div^>
echo         ^<a href="https://www.sketchup.com/en/download/all" target="_blank" class="btn"^>تحميل SketchUp من الموقع الرسمي^</a^>
echo         ^<a href="https://t.me/pro3mer/254" target="_blank" class="btn" style="margin-top: 10px;"^>تحميل SketchUp من التلجرام^</a^>
echo       ^</div^>
echo     ^</div^>
echo.
echo     ^<div id="SystemInfo" class="tabcontent"^>
echo       ^<div class="card"^>
echo         ^<h2^>معلومات النظام والحاسوب^</h2^>
echo         ^<div class="system-info-grid"^>
echo           ^<div class="info-card"^>
echo             ^<h4^>معلومات الحاسوب^</h4^>
echo             ^<p^>^<strong^>اسم الحاسوب:^</strong^> !COMPUTER_NAME!^</p^>
echo             ^<p^>^<strong^>اسم المستخدم:^</strong^> !USER_NAME!^</p^>
echo           ^</div^>
echo           ^<div class="info-card"^>
echo             ^<h4^>نظام التشغيل^</h4^>
echo             ^<p^>^<strong^>الإصدار:^</strong^> !Caption!^</p^>
echo             ^<p^>^<strong^>رقم الإصدار:^</strong^> !Version!^</p^>
echo             ^<p^>^<strong^>البنية:^</strong^> !OSArchitecture!^</p^>
echo           ^</div^>
echo           ^<div class="info-card"^>
echo             ^<h4^>المعالج والذاكرة^</h4^>
echo             ^<p^>^<strong^>المعالج:^</strong^> !Name!^</p^>
echo             ^<p^>^<strong^>الذاكرة:^</strong^> !RAM_GB! GB^</p^>
echo           ^</div^>
echo         ^</div^>
echo.
echo       ^</div^>
echo     ^</div^>
echo.
echo       ^</div^>
echo     ^</div^>
echo.
echo     ^<div id="Contact" class="tabcontent"^>
echo       ^<div class="contact-info"^>
echo         ^<div class="contact-card"^>
echo           ^<div class="contact-header"^>
echo             م/ عامر الحلحلي - Arch/ Amer Al-hlhli
echo           ^</div^>
echo           ^<div class="contact-links"^>
echo             ^<a href="https://t.me/pro3mer" target="_blank" class="contact-link"^>برامج هندسية - Engineering programs^</a^>
echo             ^<a href="https://t.me/apk3mer" target="_blank" class="contact-link"^>تطبيقات اندرويد مفعلة - Activated Android applications^</a^>
echo             ^<a href="https://t.me/ppt3mer" target="_blank" class="contact-link"^>ملفات باوربوينت مميزة - Distinctive PowerPoint files^</a^>
echo             ^<a href="https://www.youtube.com/@hlhli?sub_confirmation=1" target="_blank" class="contact-link"^>قناة اليوتيوب - YouTube channel^</a^>
echo           ^</div^>
echo         ^</div^>
echo       ^</div^>
echo     ^</div^>
echo.
echo     ^<footer^>
echo       ^<p^>تم إنشاء هذا التقرير تلقائيًا بواسطة سكربت تثبيت إضافات SketchUp^</p^>
echo     ^</footer^>
echo   ^</div^>
echo.
echo   ^<script^>
echo     function openTab^(evt, tabName^) {
echo       var i, tabcontent, tablinks;
echo       tabcontent = document.getElementsByClassName^("tabcontent"^);
echo       for ^(i = 0; i ^< tabcontent.length; i++^) {
echo         tabcontent[i].style.display = "none";
echo       }
echo       tablinks = document.getElementsByClassName^("tablinks"^);
echo       for ^(i = 0; i ^< tablinks.length; i++^) {
echo         tablinks[i].className = tablinks[i].className.replace^(" active", ""^);
echo       }
echo       document.getElementById^(tabName^).style.display = "block";
echo       evt.currentTarget.className += " active";
echo     }
echo   ^</script^>
echo ^</body^>
echo ^</html^>
) > "%HTML_REPORT%"


echo %GREEN%HTML report generated: %HTML_REPORT%%RESET%
timeout /t 2 >nul

start "" "%HTML_REPORT%"
echo %GREEN%Report opened.%RESET%



timeout /t 2 >nul

popd
endlocal
exit /B 1