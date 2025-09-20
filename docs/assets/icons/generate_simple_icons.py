#!/usr/bin/env python3
"""
AIスタイリスト - シンプルアイコン生成スクリプト
Pillowのみを使用してアイコンを生成
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

# アイコンサイズ定義
ICON_SIZES = {
    'app_icon_1024.png': 1024,
    'app_icon_180.png': 180,
    'app_icon_120.png': 120,
    'app_icon_87.png': 87,
    'app_icon_80.png': 80,
    'app_icon_60.png': 60,
    'app_icon_58.png': 58,
    'app_icon_40.png': 40,
    'app_icon_29.png': 29,
    'app_icon_20.png': 20,
}

def create_app_icon(size):
    """
    AIスタイリストのアイコンを生成
    """
    # 背景作成（グラデーション風）
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # 背景グラデーション効果
    center = size // 2
    for r in range(center, 0, -5):
        # ピンクからブルーへのグラデーション
        ratio = (center - r) / center
        red = int(255 * (1 - ratio * 0.3))
        green = int(240 + ratio * 15)
        blue = int(240 + ratio * 15)
        alpha = max(20, int(100 - ratio * 80))
        
        color = (red, green, blue, alpha)
        draw.ellipse([center-r, center-r, center+r, center+r], fill=color)
    
    # 中央の鏡を表現する円
    mirror_radius = int(size * 0.35)
    mirror_center = center
    
    # 鏡のフレーム（グラデーション風）
    frame_width = max(2, size // 50)
    for i in range(frame_width):
        # ピンクからブルーのフレーム
        ratio = i / frame_width
        red = int(255 - ratio * 50)  # 255 -> 205
        green = int(182 + ratio * 24)  # 182 -> 206
        blue = int(193 + ratio * 42)  # 193 -> 235
        
        frame_color = (red, green, blue, 255)
        draw.ellipse([
            mirror_center - mirror_radius - i,
            mirror_center - mirror_radius - i,
            mirror_center + mirror_radius + i,
            mirror_center + mirror_radius + i
        ], outline=frame_color, width=1)
    
    # 鏡の内側（光沢効果）
    inner_radius = mirror_radius - frame_width - 2
    for r in range(inner_radius, 0, -3):
        alpha = max(50, int(200 - (inner_radius - r) * 3))
        shine_color = (255, 255, 255, alpha)
        draw.ellipse([
            mirror_center - r,
            mirror_center - r,
            mirror_center + r,
            mirror_center + r
        ], fill=shine_color)
    
    # カラーパレットを表現する小さな円（4色）
    palette_radius = max(8, size // 25)
    palette_distance = int(size * 0.25)
    
    colors = [
        (255, 179, 71, 200),   # イエベ オレンジ
        (240, 230, 140, 200),  # イエベ イエロー
        (135, 206, 235, 200),  # ブルベ スカイブルー
        (221, 160, 221, 200),  # ブルベ プラム
    ]
    
    positions = [
        (center - palette_distance * 0.7, center - palette_distance * 0.7),  # 左上
        (center + palette_distance * 0.7, center - palette_distance * 0.7),  # 右上
        (center - palette_distance * 0.7, center + palette_distance * 0.7),  # 左下
        (center + palette_distance * 0.7, center + palette_distance * 0.7),  # 右下
    ]
    
    for i, (x, y) in enumerate(positions):
        color = colors[i]
        # パレットの影
        draw.ellipse([x-palette_radius+2, y-palette_radius+2, 
                     x+palette_radius+2, y+palette_radius+2], 
                    fill=(0, 0, 0, 50))
        # パレット本体
        draw.ellipse([x-palette_radius, y-palette_radius, 
                     x+palette_radius, y+palette_radius], 
                    fill=color)
        # パレットのハイライト
        highlight_radius = max(2, palette_radius // 3)
        draw.ellipse([x-highlight_radius, y-highlight_radius-palette_radius//3,
                     x+highlight_radius, y+highlight_radius-palette_radius//3],
                    fill=(255, 255, 255, 150))
    
    # 中央にAIを表現する星やキラキラ
    if size >= 40:
        star_size = max(4, size // 40)
        # メインの星
        star_points = []
        for i in range(10):
            angle = (i * math.pi) / 5
            if i % 2 == 0:
                radius = star_size * 2
            else:
                radius = star_size
            x = center + radius * math.cos(angle - math.pi/2)
            y = center + radius * math.sin(angle - math.pi/2)
            star_points.append((x, y))
        
        draw.polygon(star_points, fill=(255, 215, 0, 200))
        
        # 小さなキラキラ
        if size >= 80:
            sparkles = [
                (center - 20, center - 30),
                (center + 25, center - 20),
                (center - 25, center + 25),
                (center + 20, center + 30),
            ]
            
            for sx, sy in sparkles:
                if size >= 120:
                    # 十字の形でキラキラ
                    sparkle_size = max(1, size // 100)
                    draw.line([sx-sparkle_size*2, sy, sx+sparkle_size*2, sy], 
                             fill=(255, 255, 255, 180), width=sparkle_size)
                    draw.line([sx, sy-sparkle_size*2, sx, sy+sparkle_size*2], 
                             fill=(255, 255, 255, 180), width=sparkle_size)
                else:
                    # シンプルな点
                    draw.ellipse([sx-1, sy-1, sx+1, sy+1], fill=(255, 255, 255, 200))
    
    # 透明度を削除して不透明な画像にする（App Store要件）
    final_img = Image.new('RGB', (size, size), (255, 255, 255))
    final_img.paste(img, (0, 0), img)
    
    return final_img

def main():
    """メイン処理"""
    print("🎨 AIスタイリスト - アイコン生成開始")
    
    script_dir = Path(__file__).parent
    success_count = 0
    
    for filename, size in ICON_SIZES.items():
        try:
            print(f"📱 生成中: {filename} ({size}x{size}px)")
            icon = create_app_icon(size)
            output_path = script_dir / filename
            icon.save(output_path, 'PNG', quality=95, optimize=True)
            print(f"✅ 完了: {filename}")
            success_count += 1
        except Exception as e:
            print(f"❌ エラー: {filename} - {e}")
    
    total_count = len(ICON_SIZES)
    print(f"\n📊 結果: {success_count}/{total_count} 個のアイコンを生成しました")
    
    if success_count == total_count:
        print("🎉 すべてのアイコンが正常に生成されました！")
        print("\n📝 次のステップ:")
        print("1. 生成されたアイコンファイルを確認")
        print("2. iOS プロジェクトにコピー:")
        print("   cp *.png ../../client/personal_color_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/")
        print("3. App Store Connect にアップロード")
        return True
    else:
        print("⚠️ 一部のアイコンの生成に失敗しました")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
