@echo off
chcp 65001 > nul
cd /d %~dp0
set LOG=%~dp0clickdown_log.txt

echo ========================================== > "%LOG%"
echo   클릭다운 원클릭 센터 로그 >> "%LOG%"
echo ========================================== >> "%LOG%"

:menu
cls
echo ==========================================
echo   클릭다운 원클릭 센터
echo ==========================================
echo 1^) 바로 실행 (프로그램 열기)
echo 2^) EXE 만들고 실행
echo 3^) 설치파일(Setup.exe) 만들기
echo 4^) 종료
echo.
set /p PICK=번호를 입력하세요 [1-4] : 

if "%PICK%"=="1" goto :run_app
if "%PICK%"=="2" goto :build_exe
if "%PICK%"=="3" goto :build_setup
if "%PICK%"=="4" goto :eof

echo.
echo [오류] 1~4 중에서만 입력해 주세요.
pause
goto :menu

:run_app
call :prepare_python
if errorlevel 1 goto :menu

echo [실행] 프로그램을 시작합니다...
%PY_CMD% app.py >> "%LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [오류] 실행 실패. 로그 파일을 확인해 주세요.
  echo 로그: %LOG%
  pause
)
goto :menu

:build_exe
call :prepare_python
if errorlevel 1 goto :menu

echo [빌드] EXE 생성 중... (처음엔 몇 분 걸릴 수 있음)
%PY_CMD% -m PyInstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py >> "%LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [오류] EXE 빌드 실패. 로그 확인: %LOG%
  pause
  goto :menu
)

echo [완료] dist\클릭다운.exe 생성됨
if exist "dist\클릭다운.exe" start "" "dist\클릭다운.exe"
pause
goto :menu

:build_setup
call :prepare_python
if errorlevel 1 goto :menu
call :find_iscc
if errorlevel 1 (
  echo.
  echo [안내] Inno Setup이 필요합니다.
  echo 1^) https://jrsoftware.org/isdl.php 에서 Inno Setup 설치
  echo 2^) 설치 후 다시 3번 선택
  pause
  goto :menu
)

echo [빌드] EXE 생성 중...
%PY_CMD% -m PyInstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py >> "%LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [오류] EXE 빌드 실패. 로그 확인: %LOG%
  pause
  goto :menu
)

echo [빌드] 설치파일 생성 중...
"%ISCC_CMD%" installer.iss >> "%LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [오류] 설치파일 생성 실패. 로그 확인: %LOG%
  pause
  goto :menu
)

echo [완료] dist\클릭다운_설치파일.exe 생성됨
if exist "dist\클릭다운_설치파일.exe" start "" "dist\클릭다운_설치파일.exe"
pause
goto :menu

:prepare_python
call :find_python
if errorlevel 1 (
  echo.
  echo [오류] Python을 찾지 못했습니다.
  echo https://www.python.org/downloads/ 에서 설치 후
  echo 설치 중 "Add Python to PATH"를 체크해 주세요.
  pause
  exit /b 1
)

echo [준비] Python 확인: %PY_CMD%
%PY_CMD% -m pip install --upgrade pip >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [오류] pip 업데이트 실패. 로그 확인: %LOG%
  pause
  exit /b 1
)
%PY_CMD% -m pip install -r requirements.txt >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [오류] 패키지 설치 실패. 로그 확인: %LOG%
  pause
  exit /b 1
)
exit /b 0

:find_python
python --version > nul 2>&1
if not errorlevel 1 (
  set PY_CMD=python
  exit /b 0
)
py -3 --version > nul 2>&1
if not errorlevel 1 (
  set PY_CMD=py -3
  exit /b 0
)
exit /b 1

:find_iscc
where ISCC > nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%i in ('where ISCC') do set ISCC_CMD=%%i
  exit /b 0
)
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
  set ISCC_CMD=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe
  exit /b 0
)
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
  set ISCC_CMD=%ProgramFiles%\Inno Setup 6\ISCC.exe
  exit /b 0
)
exit /b 1
