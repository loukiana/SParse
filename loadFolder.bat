@echo off
setlocal enabledelayedexpansion
rem NODE must point to node.exe
set NODE=node
rem memomry usage
set MEM=4000
rem DIR is input folder and first param
set DIR=%~1
rem DB is second param and is mysql database name
set DB=%~2
set BASEDIR=%CD%

call :treeProcess
goto :eof

:treeProcess
rem load each file in this folder
cd "%DIR%"
for /R %%f in (*.log) do (
  set B=%%~dpf
  rem C - path relative to DIR
  set C=!B:%DIR%\=!
  pushd %BASEDIR%
  echo Loading file !C!%%~nf
  call %NODE% --max-old-space-size=%MEM% --expose-gc parser.js "%%~ff" "!C!%%~nf" "%DB%"
  popd
  )
cd %BASEDIR%

echo Done.
exit /b

rem load files in subfolders
for /D %%d in (*) do (
    cd %%d
    set PREFIX0=%PREFIX%
    set PREFIX=%PREFIX%_%%d
    call :treeProcess
    cd ..
)
exit /b