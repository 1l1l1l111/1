@echo off
chcp 65001 > nul
cd /d %~dp0
set LOG=%~dp0build_exe_log.txt

echo ========================================== > "%LOG%"
echo   클릭다운 원클릭 EXE 만들기 + 실행 로그 >> "%LOG%"
echo ========================================== >> "%LOG%"

call :find_python
if errorlevel 1 goto :python_fail

echo [1/5] Python 확인 완료: %PY_CMD%
echo [1/5] Python 확인 완료: %PY_CMD%>> "%LOG%"

echo [2/5] pip 업데이트...
%PY_CMD% -m pip install --upgrade pip >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail

echo [3/5] 필요한 패키지 설치...
%PY_CMD% -m pip install -r requirements.txt >> "%LOG%" 2>&1
if errorlevel 1 goto :pip_fail

echo [4/5] EXE 빌드 중... (처음엔 몇 분 걸릴 수 있음)
%PY_CMD% -m PyInstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py >> "%LOG%" 2>&1
if errorlevel 1 goto :build_fail

echo [5/5] EXE 실행...
if exist "dist\클릭다운.exe" (
  start "" "dist\클릭다운.exe"
  echo.
  echo 완료! dist\클릭다운.exe 생성 + 실행 완료
  echo 로그 파일: %LOG%
) else (
  goto :not_found
)

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

:python_fail
echo.
echo [오류] Python을 찾지 못했습니다.
echo 1) https://www.python.org/downloads/ 에서 설치
echo 2) 설치할 때 "Add Python to PATH" 체크
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
echo 보안 프로그램이 막는 경우 예외 처리 후 다시 시도해 주세요.
echo 로그 파일: %LOG%
pause
exit /b 1

:not_found
echo.
echo [오류] EXE 파일이 생성되지 않았습니다: dist\클릭다운.exe
echo 로그 파일: %LOG%
pause
exit /b 1
