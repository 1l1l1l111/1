@echo off
chcp 65001 > nul
cd /d %~dp0

echo ==========================================
echo   클릭다운 설치파일(Setup.exe) 원클릭 생성
echo ==========================================

echo [1/6] Python 설치 확인...
python --version > nul 2>&1
if errorlevel 1 goto :python_fail

echo [2/6] 필요한 패키지 설치...
python -m pip install --upgrade pip
if errorlevel 1 goto :pip_fail
python -m pip install -r requirements.txt
if errorlevel 1 goto :pip_fail

echo [3/6] EXE 빌드...
pyinstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py
if errorlevel 1 goto :build_fail

echo [4/6] Inno Setup(ISCC) 확인...
where ISCC > nul 2>&1
if errorlevel 1 goto :inno_fail

echo [5/6] 설치파일 생성...
ISCC installer.iss
if errorlevel 1 goto :setup_fail

echo [6/6] 완료!
echo dist\클릭다운_설치파일.exe 가 생성되었습니다.
if exist "dist\클릭다운_설치파일.exe" start "" "dist\클릭다운_설치파일.exe"
echo.
pause
exit /b 0

:python_fail
echo.
echo [오류] Python이 설치되어 있지 않습니다.
echo https://www.python.org/downloads/ 에서 설치 후 다시 실행해 주세요.
echo.
pause
exit /b 1

:pip_fail
echo.
echo [오류] 패키지 설치에 실패했습니다. 인터넷 연결을 확인해 주세요.
echo.
pause
exit /b 1

:build_fail
echo.
echo [오류] EXE 빌드 실패. 잠시 후 다시 시도해 주세요.
echo.
pause
exit /b 1

:inno_fail
echo.
echo [안내] Inno Setup이 필요합니다.
echo 1) https://jrsoftware.org/isdl.php 접속
echo 2) Inno Setup 설치
echo 3) 설치 후 이 파일을 다시 더블클릭
echo.
pause
exit /b 1

:setup_fail
echo.
echo [오류] 설치파일 생성 실패. 다시 시도해 주세요.
echo.
pause
exit /b 1
