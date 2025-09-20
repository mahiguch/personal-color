#!/usr/bin/env python3
"""
AIスタイリストのアイコン生成スクリプト（PIL版）
フォールバック用の高品質アイコンを生成
"""

import os
import sys
import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("Pillowがインストールされていません:")
    print("pip install pillow")
    sys.exit(1)

# アイコンサイズ定義（iOS用）
ICON_SIZES = {
    # App Store用
    'app_icon_1024.png': 1024,
    
    # iPhone App
    'app_icon_180.png': 180,  # @3x
    'app_icon_120.png': 120,  # @2x
    'app_icon_60.png': 60,    # @1x
    
    # iPhone Settings
    'app_icon_87.png': 87,    # @3x
    'app_icon_58.png': 58,    # @2x  
    'app_icon_29.png': 29,    # @1x
    
    # iPhone Spotlight
    'app_icon_80.png': 80,    # @2x
    'app_icon_40.png': 40,    # @1x
    
    # iPhone Notification
    'app_icon_20.png': 20,    # @1x
}

def create_radial_gradient(size, colors, center=None):
    """
    放射状グラデーションを作成
    """
    if center is None:
        center = (size // 2, size // 2)
    
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    
    max_distance = math.sqrt(size**2 + size**2) // 2
    
    for y in range(size):
        for x in range(size):
            distance = math.sqrt((x - center[0])**2 + (y - center[1])**2)
            ratio = min(distance / max_distance, 1.0)
            
            # 3色グラデーション（ピンク→白→ブルー）
            if ratio < 0.5:
                # ピンク→白
                t = ratio * 2
                r = int(255 * (1 - t) + 255 * t)      # 255→255
                g = int(182 * (1 - t) + 255 * t)      # 182→255  
                b = int(193 * (1 - t) + 255 * t)      # 193→255
            else:
                # 白→ブルー
                t = (ratio - 0.5) * 2
                r = int(255 * (1 - t) + 135 * t)      # 255→135
                g = int(255 * (1 - t) + 206 * t)      # 255→206
                b = int(255 * (1 - t) + 235 * t)      # 255→235
            
            draw.point((x, y), fill=(r, g, b))
    
    return img

def draw_star(draw, center, size, color, fill=True):
    """
    星を描画
    """
    x, y = center
    points = []
    
    for i in range(10):
        angle = i * math.pi / 5 - math.pi / 2
        if i % 2 == 0:
            radius = size
        else:
            radius = size * 0.4
        
        px = x + radius * math.cos(angle)
        py = y + radius * math.sin(angle)
        points.append((px, py))
    
    if fill:
        draw.polygon(points, fill=color)
    else:
        # 星の輪郭のみ
        for i in range(len(points)):
            start = points[i]
            end = points[(i + 1) % len(points)]
            draw.line([start, end], fill=color, width=2)

def create_high_quality_icon(size):
    """
    高品質なAIスタイリストアイコンを生成
    """
    # 背景グラデーション
    img = create_radial_gradient(size, ['#FFB6C1', '#FFFFFF', '#87CEEB'])
    draw = ImageDraw.Draw(img)
    
    # 計算用の基準値
    center = size // 2
    
    # メインの鏡/レンズ（大きな円）
    mirror_radius = int(size * 0.28)  # 28%の半径
    mirror_outline_width = max(1, size // 128)
    
    # 外側のリング（装飾）
    ring_radius = int(size * 0.34)
    draw.ellipse([center - ring_radius, center - ring_radius,
                 center + ring_radius, center + ring_radius],
                outline='#FFB6C1', width=max(1, size // 512))
    
    # メイン鏡の外枠
    draw.ellipse([center - mirror_radius, center - mirror_radius,
                 center + mirror_radius, center + mirror_radius],
                fill=None, outline='#FFFFFF', width=mirror_outline_width)
    
    # 鏡の内側反射効果（ハイライト）
    highlight_radius = int(mirror_radius * 0.85)
    highlight_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight_img)
    
    # 内側の円（薄い白でハイライト効果）
    highlight_draw.ellipse([center - highlight_radius, center - highlight_radius,
                           center + highlight_radius, center + highlight_radius],
                          fill=(255, 255, 255, 40))
    
    # 上側のハイライト（鏡の反射効果）
    small_highlight = int(highlight_radius * 0.6)
    highlight_center_y = center - int(highlight_radius * 0.3)
    highlight_draw.ellipse([center - small_highlight, highlight_center_y - small_highlight//2,
                           center + small_highlight, highlight_center_y + small_highlight//2],
                          fill=(255, 255, 255, 80))
    
    img = Image.alpha_composite(img.convert('RGBA'), highlight_img).convert('RGB')
    draw = ImageDraw.Draw(img)
    
    # カラースウォッチ（4方向）
    swatch_radius = max(5, size // 20)  # 最小5px
    swatch_distance = int(size * 0.35)
    swatch_colors = [
        (255, 215, 0),    # ゴールド（イエベ）
        (255, 106, 106),  # コーラル（暖色）
        (78, 205, 196),   # ターコイズ（ブルベ）
        (168, 230, 207)   # ミント（冷色）
    ]
    
    # 4方向の位置
    positions = [
        (center, center - swatch_distance),  # 上
        (center + swatch_distance, center),  # 右
        (center, center + swatch_distance),  # 下  
        (center - swatch_distance, center)   # 左
    ]
    
    for i, ((x, y), color) in enumerate(zip(positions, swatch_colors)):
        # カラースウォッチの影効果
        shadow_offset = max(1, size // 200)
        draw.ellipse([x - swatch_radius + shadow_offset, y - swatch_radius + shadow_offset,
                     x + swatch_radius + shadow_offset, y + swatch_radius + shadow_offset],
                    fill=(0, 0, 0, 20) if size >= 60 else (0, 0, 0))
        
        # メインのカラースウォッチ
        draw.ellipse([x - swatch_radius, y - swatch_radius,
                     x + swatch_radius, y + swatch_radius],
                    fill=color, outline='#FFFFFF', 
                    width=max(1, size // 200))
    
    # 中央の星（AIシンボル）
    if size >= 40:
        star_size = max(8, size // 40)
        draw_star(draw, (center, center - size//15), star_size, '#FFFFFF')
    
    # 小さなキラキラ効果
    if size >= 60:
        sparkle_size = max(2, size // 100)
        sparkle_positions = [
            (center - size//6, center - size//8),
            (center + size//5, center - size//10),
            (center - size//8, center + size//6),
            (center + size//7, center + size//6),
        ]
        
        sparkle_colors = ['#FFD700', '#87CEEB', '#FFB6C1', '#98FB98']
        
        for (x, y), color_hex in zip(sparkle_positions, sparkle_colors):
            # hex to rgb
            color_rgb = tuple(int(color_hex[i:i+2], 16) for i in (1, 3, 5))
            draw.ellipse([x - sparkle_size, y - sparkle_size,
                         x + sparkle_size, y + sparkle_size],
                        fill=color_rgb)
    
    # 中央下部のAI診断チップ（小さなインジケーター）
    if size >= 80:
        chip_width = size // 25
        chip_height = size // 50
        chip_x = center - chip_width // 2
        chip_y = center + size // 15
        
        # チップの背景
        draw.rounded_rectangle([chip_x, chip_y, chip_x + chip_width, chip_y + chip_height],
                              radius=chip_height // 2, fill='#4ECDC4', outline='#FFFFFF')
        
        # 3つの小さなドット
        dot_size = max(1, size // 300)
        if dot_size > 0:
            dot_spacing = chip_width // 4
            start_x = chip_x + dot_spacing
            dot_y = chip_y + chip_height // 2
            
            for i in range(3):
                x = start_x + i * dot_spacing
                draw.ellipse([x - dot_size, dot_y - dot_size,
                             x + dot_size, dot_y + dot_size],
                            fill='#FFFFFF')
    
    return img

def generate_all_icons():
    """
    全サイズのアイコンを生成
    """
    script_dir = Path(__file__).parent
    print("🎨 AIスタイリスト アイコン生成開始")
    print("=" * 60)
    
    success_count = 0
    
    for filename, size in ICON_SIZES.items():
        output_path = script_dir / filename
        
        try:
            print(f"  📱 {filename} ({size}×{size}px) を生成中...")
            
            # 高品質アイコン生成
            icon = create_high_quality_icon(size)
            
            # 最終品質チェック・調整
            if icon.size != (size, size):
                icon = icon.resize((size, size), Image.Resampling.LANCZOS)
            
            # RGB形式で保存（透明背景なし）
            if icon.mode != 'RGB':
                icon = icon.convert('RGB')
            
            # 高品質で保存
            icon.save(output_path, 'PNG', optimize=True, quality=95)
            
            # ファイルサイズ確認
            file_size = output_path.stat().st_size
            print(f"    ✅ 生成完了 ({file_size/1024:.1f}KB)")
            
            success_count += 1
            
        except Exception as e:
            print(f"    ❌ 生成エラー: {e}")
    
    print(f"\n🎯 完了: {success_count}/{len(ICON_SIZES)} アイコンを生成")
    return success_count == len(ICON_SIZES)

def verify_generated_icons():
    """
    生成されたアイコンの検証
    """
    script_dir = Path(__file__).parent
    print("\n🔍 アイコン品質検証中...")
    
    issues = []
    total_size = 0
    
    for filename, expected_size in ICON_SIZES.items():
        file_path = script_dir / filename
        
        if not file_path.exists():
            issues.append(f"❌ {filename}: ファイル不在")
            continue
        
        try:
            with Image.open(file_path) as img:
                # 基本チェック
                if img.size != (expected_size, expected_size):
                    issues.append(f"⚠️ {filename}: サイズ不正 {img.size}")
                if img.format != 'PNG':
                    issues.append(f"⚠️ {filename}: フォーマット不正 {img.format}")
                if img.mode not in ('RGB', 'L'):
                    issues.append(f"⚠️ {filename}: カラーモード {img.mode}")
                
                # ファイルサイズ
                file_size = file_path.stat().st_size
                total_size += file_size
                
                if expected_size >= 120 and file_size < 3000:
                    issues.append(f"⚠️ {filename}: 小サイズ {file_size}B")
                elif file_size > 300000:
                    issues.append(f"⚠️ {filename}: 大サイズ {file_size}B")
                
        except Exception as e:
            issues.append(f"❌ {filename}: 読み込みエラー {e}")
    
    print(f"📊 合計ファイルサイズ: {total_size/1024:.1f}KB")
    
    if issues:
        print("⚠️ 品質チェック結果:")
        for issue in issues:
            print(f"  {issue}")
        return False
    else:
        print("✅ 全アイコンが品質基準クリア")
        return True

def main():
    """
    メイン実行
    """
    print("🚀 AIスタイリスト")
    print("🎨 高品質アイコン生成システム")
    print("=" * 60)
    
    # アイコン生成
    generation_ok = generate_all_icons()
    
    # 検証
    verification_ok = verify_generated_icons()
    
    print("\n" + "=" * 60)
    
    if generation_ok and verification_ok:
        print("🎉 アイコン生成完了！")
        print("\n📋 次のステップ:")
        print("1. Flutterプロジェクトへコピー:")
        print("   cp *.png ../../../client/personal_color_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/")
        print("2. Xcodeで確認・設定")
        print("3. flutter_launcher_icons で自動設定")
        return True
    else:
        print("❌ 一部処理でエラー発生")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)