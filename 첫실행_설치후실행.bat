@echo off
chcp 65001 > nul
cd /d %~dp0

echo [1/3] Python 확인...
python --version > nul 2>&1
if errorlevel 1 (
  echo Python이 설치되어 있지 않습니다.
  echo https://www.python.org/downloads/ 에서 설치 후 다시 실행하세요.
  pause
  exit /b 1
)

echo [2/3] 필요한 모듈 설치...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo [3/3] 프로그램 실행...
python app.py
pause
