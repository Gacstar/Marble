@echo off
cd /d "%~dp0"
powershell -WindowStyle Hidden -Command "python tools/card_editor_server.py"
