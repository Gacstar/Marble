#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import csv
import json
import shutil
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading
import webbrowser

# 設定目錄結構
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

CARDS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "gameplay", "cards", "food", "cards.csv")
SKILLS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "gameplay", "cards", "food", "skills.csv")
TEXTURES_DIR = os.path.join(ROOT_DIR, "MarbleGame", "assets", "textures")
HTML_FILE = os.path.join(SCRIPT_DIR, "card_editor.html")

PORT = 8000

# 預先定義欄位名稱
CARDS_HEADERS = ['card_id', 'name', 'skill_a_id', 'skill_a_value', 'skill_b_id', 'skill_b_value', 'slots', 'icon']
SKILLS_HEADERS = ['skill_id', 'skill_type', 'display_text', 'color_a', 'color_b']

class CardEditorHandler(BaseHTTPRequestHandler):
    def end_headers(self):
        # 允許跨網域與關閉快取，以便開發時即時更新
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path

        # 1. 首頁與靜態 HTML
        if path in ('/', '/index.html', '/card_editor.html'):
            if not os.path.exists(HTML_FILE):
                self.send_error_response(404, f"Frontend HTML file not found: {HTML_FILE}")
                return
            
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.end_headers()
            with open(HTML_FILE, 'r', encoding='utf-8') as f:
                self.wfile.write(f.read().encode('utf-8'))
            return

        # 2. 獲取卡牌 API
        elif path == '/api/cards':
            if not os.path.exists(CARDS_CSV):
                self.send_error_response(404, f"cards.csv not found at {CARDS_CSV}")
                return
            
            cards = []
            try:
                with open(CARDS_CSV, mode='r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        clean_row = {k: (v.strip() if v else "") for k, v in row.items()}
                        cards.append(clean_row)
                
                self.send_json_response(200, cards)
            except Exception as e:
                self.send_error_response(500, f"Error reading cards.csv: {str(e)}")
            return

        # 3. 獲取技能 API
        elif path == '/api/skills':
            if not os.path.exists(SKILLS_CSV):
                self.send_error_response(404, f"skills.csv not found at {SKILLS_CSV}")
                return
            
            skills = []
            try:
                with open(SKILLS_CSV, mode='r', encoding='utf-8') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        clean_row = {k: (v.strip() if v else "") for k, v in row.items()}
                        skills.append(clean_row)
                
                self.send_json_response(200, skills)
            except Exception as e:
                self.send_error_response(500, f"Error reading skills.csv: {str(e)}")
            return

        # 4. 獲取可用圖示列表 API
        elif path == '/api/textures':
            if not os.path.exists(TEXTURES_DIR):
                self.send_json_response(200, [])
                return
            
            try:
                files = os.listdir(TEXTURES_DIR)
                images = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg')) and not f.endswith('.import')]
                images.sort()
                self.send_json_response(200, images)
            except Exception as e:
                self.send_error_response(500, f"Error listing textures: {str(e)}")
            return

        # 5. 獲取貼圖資源 (以 /assets/textures/ 開頭)
        elif path.startswith('/assets/textures/'):
            filename = path[len('/assets/textures/'):]
            filename = urllib.parse.unquote(filename)
            filename = os.path.basename(filename)
            
            file_path = os.path.join(TEXTURES_DIR, filename)
            if not os.path.exists(file_path):
                self.send_error_response(404, f"Texture not found: {filename}")
                return

            ext = os.path.splitext(filename)[1].lower()
            content_type = 'application/octet-stream'
            if ext in ('.jpg', '.jpeg'):
                content_type = 'image/jpeg'
            elif ext == '.png':
                content_type = 'image/png'

            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.end_headers()
            
            with open(file_path, 'rb') as f:
                self.wfile.write(f.read())
            return

        else:
            self.send_error_response(404, "Page not found")

    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path

        # 自銷毀 API：直接結束背景進程，延遲 0.5 秒以回傳 response
        if path == '/api/shutdown':
            self.send_json_response(200, {"status": "ok", "message": "Server shutting down."})
            
            def shut():
                import sys
                print("[*] Shutdown signal received. Stopping server...")
                os._exit(0)
            
            threading.Timer(0.5, shut).start()
            return

        # 取得 Request Body 長度與內容
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
        except Exception as e:
            self.send_error_response(400, f"Invalid JSON payload: {str(e)}")
            return

        # 1. 寫入卡牌 API
        if path == '/api/cards':
            if not isinstance(data, list):
                self.send_error_response(400, "Payload must be a list of cards")
                return

            if os.path.exists(CARDS_CSV):
                shutil.copyfile(CARDS_CSV, CARDS_CSV + ".bak")

            try:
                with open(CARDS_CSV, mode='w', encoding='utf-8', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(CARDS_HEADERS)
                    for card in data:
                        row = [
                            card.get('card_id', '').strip(),
                            card.get('name', '').strip(),
                            card.get('skill_a_id', '').strip(),
                            card.get('skill_a_value', '').strip(),
                            card.get('skill_b_id', '').strip(),
                            card.get('skill_b_value', '').strip(),
                            card.get('slots', '').strip(),
                            card.get('icon', '').strip()
                        ]
                        writer.writerow(row)
                
                self.send_json_response(200, {"status": "ok", "message": "Cards CSV updated successfully."})
            except Exception as e:
                if os.path.exists(CARDS_CSV + ".bak"):
                    shutil.copyfile(CARDS_CSV + ".bak", CARDS_CSV)
                self.send_error_response(500, f"Failed to save cards CSV: {str(e)}")
            return

        # 2. 寫入技能 API
        elif path == '/api/skills':
            if not isinstance(data, list):
                self.send_error_response(400, "Payload must be a list of skills")
                return

            if os.path.exists(SKILLS_CSV):
                shutil.copyfile(SKILLS_CSV, SKILLS_CSV + ".bak")

            try:
                with open(SKILLS_CSV, mode='w', encoding='utf-8', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(SKILLS_HEADERS)
                    for skill in data:
                        row = [
                            skill.get('skill_id', '').strip(),
                            skill.get('skill_type', '').strip(),
                            skill.get('display_text', '').strip(),
                            skill.get('color_a', '').strip(),
                            skill.get('color_b', '').strip()
                        ]
                        writer.writerow(row)
                
                self.send_json_response(200, {"status": "ok", "message": "Skills CSV updated successfully."})
            except Exception as e:
                if os.path.exists(SKILLS_CSV + ".bak"):
                    shutil.copyfile(SKILLS_CSV + ".bak", SKILLS_CSV)
                self.send_error_response(500, f"Failed to save skills CSV: {str(e)}")
            return

        else:
            self.send_error_response(404, "Endpoint not found")

    def send_json_response(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def send_error_response(self, status_code, message):
        self.send_json_response(status_code, {"error": message})

def open_browser():
    print(f"[*] Automatically opening browser at http://localhost:{PORT}")
    webbrowser.open(f"http://localhost:{PORT}")

def run_server():
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, CardEditorHandler)
    print("=" * 60)
    print(f"  Marble Card & Skill Editor Server is running on port {PORT}")
    print(f"  Url: http://localhost:{PORT}")
    print("=" * 60)
    
    # 啟動後延遲 1 秒自動開啟瀏覽器
    threading.Timer(1.0, open_browser).start()
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Stopping server...")
        httpd.server_close()

if __name__ == '__main__':
    run_server()
