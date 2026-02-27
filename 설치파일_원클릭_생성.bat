@echo off
chcp 65001 > nul
cd /d %~dp0
set LOG=%~dp0build_setup_log.txt

echo ========================================== > "%LOG%"
echo   클릭다운 설치파일(Setup.exe) 원클릭 생성 로그 >> "%LOG%"
echo ========================================== >> "%LOG%"

call :find_python
if errorlevel 1 goto :python_fail

echo [1/6] Python 확인 완료: %PY_CMD%
echo [1/6] Python 확인 완료: %PY_CMD%>> "%LOG%"

echo [2/6] 필요한 패키지 설치...
%PY_CMD% -m pip install --upgrade pip >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail
%PY_CMD% -m pip install -r requirements.txt >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail

echo [3/6] EXE 빌드...
%PY_CMD% -m PyInstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py >> "%LOG%" 2>&1
if errorlevel 1 goto :build_fail

echo [4/6] Inno Setup(ISCC) 확인...
call :find_iscc
if errorlevel 1 goto :inno_fail

echo [5/6] 설치파일 생성...
"%ISCC_CMD%" installer.iss >> "%LOG%" 2>&1
if errorlevel 1 goto :setup_fail

echo [6/6] 완료!
echo dist\클릭다운_설치파일.exe 가 생성되었습니다.
if exist "dist\클릭다운_설치파일.exe" start "" "dist\클릭다운_설치파일.exe"
echo 로그 파일: %LOG%
echo.
pause
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

:python_fail
echo.
echo [오류] Python을 찾지 못했습니다.
echo https://www.python.org/downloads/ 에서 설치 후 다시 시도해 주세요.
pause
exit /b 1

:pip_fail
echo.
echo [오류] 패키지 설치 실패. 인터넷 연결 확인 필요
echo 로그 파일: %LOG%
pause
exit /b 1

:build_fail
echo.
echo [오류] EXE 빌드 실패
echo 로그 파일: %LOG%
pause
exit /b 1

:inno_fail
echo.
echo [안내] Inno Setup이 필요합니다.
echo 1) https://jrsoftware.org/isdl.php 접속
echo 2) Inno Setup 설치
echo 3) 설치 후 이 파일 다시 실행
pause
exit /b 1

:setup_fail
echo.
echo [오류] 설치파일 생성 실패
echo 로그 파일: %LOG%
pause
exit /b 1
