@echo off
chcp 65001 > nul
cd /d %~dp0

echo ==========================================
echo   클릭다운 원클릭 EXE 만들기 + 실행
echo ==========================================

echo [1/5] Python 설치 확인...
python --version > nul 2>&1
if errorlevel 1 (
  echo.
  echo [오류] Python이 설치되어 있지 않습니다.
  echo 아래 주소에서 Python 설치 후, 다시 이 파일을 더블클릭하세요.
  echo https://www.python.org/downloads/
  echo.
  pause
  exit /b 1
)

echo [2/5] pip 업데이트...
python -m pip install --upgrade pip
if errorlevel 1 goto :pip_fail

echo [3/5] 필요한 패키지 설치...
python -m pip install -r requirements.txt
if errorlevel 1 goto :pip_fail

echo [4/5] EXE 빌드 중... (처음엔 몇 분 걸릴 수 있음)
pyinstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py
if errorlevel 1 goto :build_fail

echo [5/5] EXE 실행...
if exist "dist\클릭다운.exe" (
  start "" "dist\클릭다운.exe"
  echo.
  echo 완료! dist\클릭다운.exe 가 생성되었고 바로 실행했습니다.
) else (
  echo [오류] EXE 파일을 찾지 못했습니다: dist\클릭다운.exe
)

echo.
pause
exit /b 0

:pip_fail
echo.
echo [오류] 패키지 설치에 실패했습니다.
echo 인터넷 연결 상태를 확인하고 다시 시도해 주세요.
echo.
pause
exit /b 1

:build_fail
echo.
echo [오류] EXE 빌드에 실패했습니다.
echo 잠시 후 다시 시도하거나, 보안 프로그램 예외 설정 후 재시도해 주세요.
echo.
pause
exit /b 1
