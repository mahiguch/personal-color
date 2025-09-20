#!/usr/bin/env python3
"""
AIスタイリストのアイコン生成スクリプト
SVGからiOS用の全サイズPNGアイコンを生成
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
    import cairosvg
except ImportError:
    print("必要なライブラリがインストールされていません:")
    print("pip install pillow cairosvg")
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

def create_fallback_icon(size):
    """
    SVG変換が失敗した場合のフォールバック用アイコンを生成
    """
    # 背景グラデーション風の円形アイコンを生成
    img = Image.new('RGB', (size, size), '#FFB6C1')
    draw = ImageDraw.Draw(img)
    
    # 中央の円（鏡効果）
    margin = size // 8
    draw.ellipse([margin, margin, size-margin, size-margin], 
                fill='#FFFFFF', outline='#87CEEB', width=max(1, size//100))
    
    # 内側の円
    inner_margin = size // 4
    draw.ellipse([inner_margin, inner_margin, size-inner_margin, size-inner_margin], 
                fill='#F0F8FF', outline='#FFB6C1', width=max(1, size//200))
    
    # 4つのカラースポット
    spot_size = size // 10
    center = size // 2
    distance = size // 3
    
    colors = ['#FFD700', '#FF6B6B', '#4ECDC4', '#A8E6CF']
    positions = [
        (center, margin + spot_size),           # 上
        (size - margin - spot_size, center),    # 右  
        (center, size - margin - spot_size),    # 下
        (margin + spot_size, center)            # 左
    ]
    
    for i, (color, (x, y)) in enumerate(zip(colors, positions)):
        draw.ellipse([x-spot_size//2, y-spot_size//2, 
                     x+spot_size//2, y+spot_size//2], fill=color)
    
    # 中央の星
    if size >= 60:
        star_size = size // 20
        star_points = []
        import math
        for i in range(10):
            angle = i * math.pi / 5
            if i % 2 == 0:
                radius = star_size
            else:
                radius = star_size // 2
            x = center + radius * math.cos(angle - math.pi/2)
            y = center + radius * math.sin(angle - math.pi/2)
            star_points.append((x, y))
        draw.polygon(star_points, fill='#FFFFFF', outline='#87CEEB')
    
    return img

def generate_icons():
    """
    SVGファイルから全サイズのPNGアイコンを生成
    """
    script_dir = Path(__file__).parent
    svg_path = script_dir / 'app_icon.svg'
    
    if not svg_path.exists():
        print(f"SVGファイルが見つかりません: {svg_path}")
        return False
    
    print("🎨 アプリアイコンを生成中...")
    
    success_count = 0
    
    for filename, size in ICON_SIZES.items():
        output_path = script_dir / filename
        
        try:
            # SVGからPNGに変換
            print(f"  📱 {filename} ({size}×{size}px) を生成中...")
            
            # cairosvgでSVGをPNGに変換
            cairosvg.svg2png(
                url=str(svg_path),
                write_to=str(output_path),
                output_width=size,
                output_height=size,
                background_color='white'  # 透明背景を白に
            )
            
            # 品質確認
            with Image.open(output_path) as img:
                if img.size != (size, size):
                    print(f"    ⚠️  サイズエラー: 期待{size}×{size}, 実際{img.size}")
                    continue
                
                # RGB形式に変換（透明部分を白に）
                if img.mode in ('RGBA', 'LA'):
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'RGBA':
                        background.paste(img, mask=img.split()[-1])
                    else:
                        background.paste(img, mask=img.split()[-1])
                    img = background
                
                # 再保存（最適化）
                img.save(output_path, 'PNG', optimize=True, quality=95)
                
            print(f"    ✅ {filename} 生成完了")
            success_count += 1
            
        except Exception as e:
            print(f"    ❌ {filename} 生成エラー: {e}")
            print(f"    🔄 フォールバックアイコンを生成...")
            
            try:
                # フォールバック用アイコンを生成
                fallback_img = create_fallback_icon(size)
                fallback_img.save(output_path, 'PNG', optimize=True, quality=95)
                print(f"    ✅ {filename} フォールバック生成完了")
                success_count += 1
            except Exception as e2:
                print(f"    ❌ フォールバック生成も失敗: {e2}")
    
    print(f"\n🎯 完了: {success_count}/{len(ICON_SIZES)} アイコンを生成しました")
    
    # 生成されたファイルのサイズを確認
    print("\n📊 生成ファイル情報:")
    for filename in ICON_SIZES.keys():
        file_path = script_dir / filename
        if file_path.exists():
            size_kb = file_path.stat().st_size / 1024
            print(f"  📄 {filename}: {size_kb:.1f}KB")
        else:
            print(f"  ❌ {filename}: 生成失敗")
    
    return success_count == len(ICON_SIZES)

def verify_icons():
    """
    生成されたアイコンの品質を検証
    """
    script_dir = Path(__file__).parent
    print("\n🔍 アイコン品質検証中...")
    
    issues = []
    
    for filename, expected_size in ICON_SIZES.items():
        file_path = script_dir / filename
        
        if not file_path.exists():
            issues.append(f"❌ {filename}: ファイルが存在しません")
            continue
            
        try:
            with Image.open(file_path) as img:
                # サイズ確認
                if img.size != (expected_size, expected_size):
                    issues.append(f"⚠️ {filename}: サイズ不正 {img.size} != {expected_size}×{expected_size}")
                
                # フォーマット確認
                if img.format != 'PNG':
                    issues.append(f"⚠️ {filename}: フォーマット不正 {img.format} != PNG")
                
                # 透明度確認（App Store用は不透明が必要）
                if img.mode in ('RGBA', 'LA'):
                    issues.append(f"⚠️ {filename}: 透明度あり（{img.mode}）")
                
                # ファイルサイズ確認（適切な範囲か）
                file_size = file_path.stat().st_size
                if expected_size >= 180 and file_size < 5000:  # 大きなアイコンが小さすぎる
                    issues.append(f"⚠️ {filename}: ファイルサイズが小さすぎる ({file_size}B)")
                elif file_size > 500000:  # 500KB以上は大きすぎる
                    issues.append(f"⚠️ {filename}: ファイルサイズが大きすぎる ({file_size}B)")
                
        except Exception as e:
            issues.append(f"❌ {filename}: 読み込みエラー {e}")
    
    if issues:
        print("\n⚠️ 品質チェックで問題が見つかりました:")
        for issue in issues:
            print(f"  {issue}")
        return False
    else:
        print("✅ すべてのアイコンが品質基準を満たしています")
        return True

def main():
    """
    メイン実行関数
    """
    print("🚀 AIスタイリスト アイコン生成開始")
    print("=" * 50)
    
    # アイコン生成
    generation_success = generate_icons()
    
    # 品質検証
    verification_success = verify_icons()
    
    print("\n" + "=" * 50)
    if generation_success and verification_success:
        print("🎉 アイコン生成が正常に完了しました！")
        print("\n📋 次のステップ:")
        print("1. 生成されたアイコンをFlutterプロジェクトにコピー")
        print("2. ios/Runner/Assets.xcassets/AppIcon.appiconset/ に配置")
        print("3. Contents.json を更新")
        return True
    else:
        print("❌ アイコン生成中にエラーが発生しました")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)