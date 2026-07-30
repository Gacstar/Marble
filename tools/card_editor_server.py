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

CARDS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "data", "cards.csv")
SKILLS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "data", "skills.csv")
ENEMIES_CSV = os.path.join(ROOT_DIR, "MarbleGame", "data", "enemies.csv")
ENEMY_SKILLS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "data", "enemy_skills.csv")
ITEM_CARDS_CSV = os.path.join(ROOT_DIR, "MarbleGame", "data", "item_cards.csv")
TEXTURES_DIR = os.path.join(ROOT_DIR, "MarbleGame", "assets", "textures")
HTML_FILE = os.path.join(SCRIPT_DIR, "card_editor.html")

PORT = 8000

# 預先定義欄位名稱
CARDS_HEADERS = ['card_id', 'name', 'skill_a_id', 'skill_a_value', 'skill_b_id', 'skill_b_value', 'slots', 'icon']
SKILLS_HEADERS = ['skill_id', 'skill_type', 'display_text', 'color_a', 'color_b']
ENEMIES_HEADERS = ['enemy_id', 'display_name', 'max_hp', 'icon', 'item_ids']
ENEMY_SKILLS_HEADERS = ['skill_id', 'skill_type', 'display_text']
ITEM_CARDS_HEADERS = ['item_id', 'display_name', 'icon', 'cd_default', 'skill_id', 'skill_value']

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

        # 4. 獲取敵人清單 API
        elif path == '/api/enemies':
            try:
                enemies = []
                if os.path.exists(ENEMIES_CSV):
                    with open(ENEMIES_CSV, mode='r', encoding='utf-8') as f:
                        reader = csv.DictReader(f)
                        for row in reader:
                            enemies.append(row)
                self.send_json_response(200, enemies)
            except Exception as e:
                self.send_error_response(500, f"Error reading enemies.csv: {str(e)}")
            return

        # 5. 獲取敵方技能清單 API
        elif path == '/api/enemy_skills':
            try:
                skills = []
                if os.path.exists(ENEMY_SKILLS_CSV):
                    with open(ENEMY_SKILLS_CSV, mode='r', encoding='utf-8') as f:
                        reader = csv.DictReader(f)
                        for row in reader:
                            skills.append(row)
                self.send_json_response(200, skills)
            except Exception as e:
                self.send_error_response(500, f"Error reading enemy_skills.csv: {str(e)}")
            return

        # 6. 獲取敵方道具卡清單 API
        elif path == '/api/item_cards':
            try:
                items = []
                if os.path.exists(ITEM_CARDS_CSV):
                    with open(ITEM_CARDS_CSV, mode='r', encoding='utf-8') as f:
                        reader = csv.DictReader(f)
                        for row in reader:
                            items.append(row)
                self.send_json_response(200, items)
            except Exception as e:
                self.send_error_response(500, f"Error reading item_cards.csv: {str(e)}")
            return

        # 4. 獲取可用圖示列表 API
        elif path == '/api/textures':
            if not os.path.exists(TEXTURES_DIR):
                self.send_json_response(200, [])
                return
            
            try:
                images = []
                for root, dirs, files in os.walk(TEXTURES_DIR):
                    for f in files:
                        if f.lower().endswith(('.png', '.jpg', '.jpeg')) and not f.endswith('.import'):
                            full_path = os.path.join(root, f)
                            rel_path = os.path.relpath(full_path, TEXTURES_DIR)
                            # 統一使用正斜線作為 Godot 與 Web 的路徑分隔符
                            images.append(rel_path.replace('\\', '/'))
                images.sort()
                self.send_json_response(200, images)
            except Exception as e:
                self.send_error_response(500, f"Error listing textures: {str(e)}")
            return

        # 5. 獲取貼圖資源 (以 /assets/textures/ 開頭)
        elif path.startswith('/assets/textures/'):
            filename = path[len('/assets/textures/'):]
            filename = urllib.parse.unquote(filename)
            
            # 安全防護：禁止跨目錄讀取
            if '..' in filename or filename.startswith('/') or filename.startswith('\\'):
                self.send_error_response(400, "Invalid path")
                return
                
            # 計算絕對路徑並確認仍在 TEXTURES_DIR 底下
            file_path = os.path.normpath(os.path.join(TEXTURES_DIR, filename))
            if not file_path.startswith(os.path.normpath(TEXTURES_DIR)):
                self.send_error_response(403, "Access denied")
                return
                
            if not os.path.exists(file_path) or os.path.isdir(file_path):
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

        # 3. 寫入敵人 API
        elif path == '/api/enemies':
            if not isinstance(data, list):
                self.send_error_response(400, "Payload must be a list of enemies")
                return
            if os.path.exists(ENEMIES_CSV):
                shutil.copyfile(ENEMIES_CSV, ENEMIES_CSV + ".bak")
            try:
                with open(ENEMIES_CSV, mode='w', encoding='utf-8', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(ENEMIES_HEADERS)
                    for enemy in data:
                        row = [
                            str(enemy.get('enemy_id', '')).strip(),
                            str(enemy.get('display_name', '')).strip(),
                            str(enemy.get('max_hp', '')).strip(),
                            str(enemy.get('icon', '')).strip(),
                            str(enemy.get('item_ids', '')).strip()
                        ]
                        writer.writerow(row)
                self.send_json_response(200, {"status": "ok", "message": "Enemies CSV updated successfully."})
            except Exception as e:
                if os.path.exists(ENEMIES_CSV + ".bak"):
                    shutil.copyfile(ENEMIES_CSV + ".bak", ENEMIES_CSV)
                self.send_error_response(500, f"Failed to save enemies CSV: {str(e)}")
            return

        # 4. 寫入敵方技能 API
        elif path == '/api/enemy_skills':
            if not isinstance(data, list):
                self.send_error_response(400, "Payload must be a list of enemy skills")
                return
            if os.path.exists(ENEMY_SKILLS_CSV):
                shutil.copyfile(ENEMY_SKILLS_CSV, ENEMY_SKILLS_CSV + ".bak")
            try:
                with open(ENEMY_SKILLS_CSV, mode='w', encoding='utf-8', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(ENEMY_SKILLS_HEADERS)
                    for skill in data:
                        row = [
                            str(skill.get('skill_id', '')).strip(),
                            str(skill.get('skill_type', '')).strip(),
                            str(skill.get('display_text', '')).strip()
                        ]
                        writer.writerow(row)
                self.send_json_response(200, {"status": "ok", "message": "Enemy Skills CSV updated successfully."})
            except Exception as e:
                if os.path.exists(ENEMY_SKILLS_CSV + ".bak"):
                    shutil.copyfile(ENEMY_SKILLS_CSV + ".bak", ENEMY_SKILLS_CSV)
                self.send_error_response(500, f"Failed to save enemy skills CSV: {str(e)}")
            return

        # 5. 寫入敵方道具卡 API
        elif path == '/api/item_cards':
            if not isinstance(data, list):
                self.send_error_response(400, "Payload must be a list of item cards")
                return
            if os.path.exists(ITEM_CARDS_CSV):
                shutil.copyfile(ITEM_CARDS_CSV, ITEM_CARDS_CSV + ".bak")
            try:
                with open(ITEM_CARDS_CSV, mode='w', encoding='utf-8', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(ITEM_CARDS_HEADERS)
                    for item in data:
                        row = [
                            str(item.get('item_id', '')).strip(),
                            str(item.get('display_name', '')).strip(),
                            str(item.get('icon', '')).strip(),
                            str(item.get('cd_default', '')).strip(),
                            str(item.get('skill_id', '')).strip(),
                            str(item.get('skill_value', '')).strip()
                        ]
                        writer.writerow(row)
                self.send_json_response(200, {"status": "ok", "message": "Item Cards CSV updated successfully."})
            except Exception as e:
                if os.path.exists(ITEM_CARDS_CSV + ".bak"):
                    shutil.copyfile(ITEM_CARDS_CSV + ".bak", ITEM_CARDS_CSV)
                self.send_error_response(500, f"Failed to save item cards CSV: {str(e)}")
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
