@echo off
chcp 65001 > nul
cd /d %~dp0

python -m pip install --upgrade pip
python -m pip install -r requirements.txt

pyinstaller --noconfirm --clean --windowed --onefile --name 클릭다운 app.py

echo 빌드 완료: dist\클릭다운.exe
pause
