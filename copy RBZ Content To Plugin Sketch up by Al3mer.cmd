@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
color 07
title Extract Plugins by Al3mer
mode con: cols=100 lines=50

REM Get the directory of the current script
set "scriptDir=%~dp0"
set "destinationDir=%scriptDir%Plugins"

REM Create the destination directory if it doesn't exist
if not exist "%destinationDir%" mkdir "%destinationDir%"

REM Variables to hold file names and versions
set "extractedFiles="
set "failedFiles="
set "extractedCount=0"
set "failedCount=0"
set "successfulPlugins="
set "failedPlugins="

for %%f in (*.rbz) do (
    set "filename=%%~nf"
    set "newname=!filename: =_!"
    if "!filename!" NEQ "!newname!" ren "%%f" "!newname!.rbz"
)

REM Extract Plugins
echo.
echo ====================================================
echo                Extract Plugins by Al3mer
echo ====================================================
echo.

for %%f in ("%scriptDir%*.rbz") do (
    echo Extracting %%f to %destinationDir%
    tar -xf "%%f" -C "%destinationDir%"
    if !errorlevel! equ 0 (
        set "extractedFiles=!extractedFiles! %%~nxf"
        set /a "extractedCount+=1"
    ) else (
        set "failedFiles=!failedFiles! %%~nxf"
        set /a "failedCount+=1"
    )
)

echo.
echo ====================================================
echo                SketchUp Versions
echo ====================================================
echo.

set "versions="
for /L %%v in (2018, 1, 2030) do (
    set "basePath=%APPDATA%\SketchUp\SketchUp %%v"
    if exist "!basePath!" (
        echo Installed SketchUp version: %%v
        set "versions=!versions! %%v"
    )
)

REM Check for RBZ files
if %extractedCount% equ 0 (
    echo No RBZ files found in the specified location.
	
    REM Create vbscript for the no files found message
    (
    echo Set objShell = CreateObject("WScript.Shell"^)
    echo msg = "No RBZ files found in the specified location."
    echo objShell.Popup msg, 0, "Extraction Report", 48
    ) > "%scriptDir%nofiles.vbs"

    REM Run the vbscript
    cscript /nologo "%scriptDir%nofiles.vbs"
    
        rmdir /S /Q "%destinationDir%"
    del "%scriptDir%nofiles.vbs"

)

REM Wait for 2 second before continuing
timeout /t 2 /nobreak >nul
  

REM Run the vbscript
cscript /nologo "%scriptDir%sketchup_versions.vbs"

REM Copy Plugins to installed SketchUp versions
for %%v in (%versions%) do (
    set "basePath=%APPDATA%\SketchUp\SketchUp %%v"
    xcopy /S /E /Y "%destinationDir%\*" "!basePath!\SketchUp\Plugins\" || (
        echo Error copying files to version %%v. Check permissions or destination folder.
    )
)

REM Build list of successfully copied and failed plugins
for %%f in (%extractedFiles%) do (
    if "%%~xf" equ ".rbz" (
        set "successfulPlugins=!successfulPlugins!%%~nf,"
    )
)
for %%f in (%failedFiles%) do (
    if "%%~xf" equ ".rbz" (
        set "failedPlugins=!failedPlugins!%%~nf^,"
    )
)

REM Create HTML file for farewell message
(
echo ^<!DOCTYPE html^>
echo ^<html lang="ar"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>Farewell Message^</title^>
echo     ^<style^>
echo         body {
echo             font-family: Arial, sans-serif;
echo             text-align: center;
echo             margin: 20px;
echo         }
echo         .big-text {
echo             font-size: 24px;
echo             font-weight: bold;
echo             margin-bottom: 20px;
echo         }
echo         .list {
echo             text-align: left;
echo             margin: 20px auto;
echo             width: 50%%;
echo         }
echo         table {
echo             width: 30%%;
echo             margin: 10px auto;
echo             border-collapse: collapse;
echo         }
echo         th, td {
echo             border: 3px solid black;
echo             padding: 11px;
echo             text-align: center;
echo         }
echo     ^</style^>
echo ^</head^>
echo ^<body^>
echo     ^<div class="big-text"^>Installation completed successfully.^</div^>
echo     ^<div class="big-text"^>Automatic copying of additions has been completed.^</div^>
echo     ^<div class="big-text"^>With the help of artificial intelligence chatgpt - gemeni.^</div^>

echo     ^<hr^>

echo     ^<div class="big-text"^>تم التثبيت بنجاح.^</div^>
echo     ^<div class="big-text"^>تمت عملية النسخ التلقائي للاضافات .^</div^>
echo     ^<div class="big-text"^>بمساعدة الذكاء الاصطناعي chatgpt -gemeni.^</div^>
echo     ^<hr^>

echo     ^<h2^>New components have been successfully ^<br^> added to SketchUp  "%versions%"  ^</h2^>
echo     ^<hr^>

REM Count the number of successfully copied plugins
set "successfulCount=0"
for %%f in (!successfulPlugins!) do (
    set /A successfulCount+=1
)

REM Count the number of plugins that failed to copy
set "failedCount=0"
for %%f in (!failedPlugins!) do (
    set /A failedCount+=1
)

echo     ^<div class="list"^>
echo         ^<h3^>Successfully copied plugins:= { !successfulCount^! } ^</h3^>
echo         ^<ul^>
REM List of successfully copied plugins
for %%f in (!successfulPlugins!) do (
    echo             ^<li^>%%f^</li^>
)
echo         ^</ul^>
echo     ^</div^>

echo     ^<div class="list"^>
echo         ^<h3^>Failed to copy plugins:= { ^!failedCount^! } ^</h3^>
echo         ^<ul^>
REM List of plugins that failed to copy
for %%f in (!failedPlugins!) do (
    echo             ^<li^>%%f^</li^>
)
echo         ^</ul^>
echo     ^</div^>

echo     ^<hr^>
echo     ^<table^>
echo         ^<tr^>
echo             ^<td^>^<b^>Archt/ Amer Al-hlhli^</b^>^</td^>
echo             ^<td^>^<b^>م/ عامر الحلحلي^</b^>^</td^>
echo         ^</tr^>
echo         ^<tr^>
echo             ^<td^>^<a href="https://t.me/pro3mer"^>Engineering programs^</a^>^</td^>
echo             ^<td^>^<a href="https://t.me/pro3mer"^>برامج هندسية^</a^>^</td^>
echo         ^</tr^>
echo         ^<tr^>
echo             ^<td^>^<a href="https://t.me/apk3mer"^>Activated Android applications^</a^>^</td^>
echo             ^<td^>^<a href="https://t.me/apk3mer"^>تطبيقات اندرويد مفعلة^</a^>^</td^>
echo         ^</tr^>
echo         ^<tr^>
echo             ^<td^>^<a href="https://t.me/ppt3mer"^>Distinctive PowerPoint files^</a^>^</td^>
echo             ^<td^>^<a href="https://t.me/ppt3mer"^>ملفات باوربوينت مميزة^</a^>^</td^>
echo         ^</tr^>
echo         ^<tr^>
echo             ^<td^>^<a href="https://www.youtube.com/@hlhli?sub_confirmation=1"^>YouTube channel^</a^>^</td^>
echo             ^<td^>^<a href="https://www.youtube.com/@hlhli?sub_confirmation=1"^>قناة اليوتيوب^</a^>^</td^>
echo         ^</tr^>
echo     ^</table^>
echo ^</body^>
echo ^</html^>
) > "%scriptDir%farewell_message.html"

REM Open HTML file in default browser
start "" "%scriptDir%farewell_message.html"

REM Delete the destination directory and all its contents (/S: include all subdirectories and files)
rmdir /S /Q "%destinationDir%"

REM Delete the vbscript files
del "%scriptDir%sketchup_versions.vbs"

REM Wait for 1 second before exiting
timeout /t 1 /nobreak >nul
exit
