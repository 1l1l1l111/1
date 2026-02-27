@echo off
chcp 65001 > nul
cd /d %~dp0
set LOG=%~dp0run_log.txt

echo ========================================== > "%LOG%"
echo   클릭다운 실행 로그 >> "%LOG%"
echo ========================================== >> "%LOG%"

call :find_python
if errorlevel 1 goto :python_fail

echo [1/3] Python 확인 완료: %PY_CMD%
echo [1/3] Python 확인 완료: %PY_CMD%>> "%LOG%"

echo [2/3] 필요한 모듈 설치...
%PY_CMD% -m pip install --upgrade pip >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail
%PY_CMD% -m pip install -r requirements.txt >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail

echo [3/3] 프로그램 실행...
%PY_CMD% app.py >> "%LOG%" 2>&1
if errorlevel 1 goto :run_fail

echo.
echo 정상 종료되었습니다.
echo 로그 파일: %LOG%
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

:python_fail
echo.
echo [오류] Python을 찾지 못했습니다.
echo 1) https://www.python.org/downloads/ 에서 설치
echo 2) 설치할 때 "Add Python to PATH" 체크
echo 3) 설치 후 이 파일 다시 더블클릭
pause
exit /b 1

:pip_fail
echo.
echo [오류] 패키지 설치 실패. 인터넷 연결을 확인해 주세요.
echo 자세한 원인은 로그 파일 확인: %LOG%
pause
exit /b 1

:run_fail
echo.
echo [오류] 프로그램 실행 실패.
echo 자세한 원인은 로그 파일 확인: %LOG%
pause
exit /b 1
