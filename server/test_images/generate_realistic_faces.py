#!/usr/bin/env python3
"""
パーソナルカラー診断テスト用画像生成スクリプト（改良版）
実際の顔の特徴を模擬したより現実的な画像を生成
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random


def create_face_image(
    skin_tone, hair_color, eye_color, title, filename, size=(512, 512)
):
    """顔画像を生成（パーソナルカラータイプに応じた特徴）"""
    img = Image.new("RGB", size, color="#f0f0f0")
    draw = ImageDraw.Draw(img)

    # 中心座標
    center_x, center_y = size[0] // 2, size[1] // 2

    # 顔の輪郭（楕円）
    face_width = 180
    face_height = 220
    face_left = center_x - face_width // 2
    face_top = center_y - face_height // 2 - 20
    face_right = face_left + face_width
    face_bottom = face_top + face_height

    draw.ellipse(
        [face_left, face_top, face_right, face_bottom],
        fill=skin_tone,
        outline="#d0d0d0",
        width=2,
    )

    # 髪（上部）
    hair_top = face_top - 60
    hair_bottom = face_top + 40
    draw.ellipse(
        [face_left - 20, hair_top, face_right + 20, hair_bottom], fill=hair_color
    )

    # 前髪
    bang_points = [
        (face_left + 20, face_top),
        (face_left + 40, face_top - 20),
        (face_left + 60, face_top - 15),
        (face_left + 80, face_top - 25),
        (face_left + 100, face_top - 20),
        (face_left + 120, face_top - 25),
        (face_left + 140, face_top - 15),
        (face_left + 160, face_top),
    ]
    draw.polygon(bang_points, fill=hair_color)

    # 目
    eye_y = center_y - 30
    eye_width = 25
    eye_height = 15

    # 左目
    left_eye_x = center_x - 35
    draw.ellipse(
        [
            left_eye_x - eye_width // 2,
            eye_y - eye_height // 2,
            left_eye_x + eye_width // 2,
            eye_y + eye_height // 2,
        ],
        fill="white",
    )
    draw.ellipse([left_eye_x - 8, eye_y - 8, left_eye_x + 8, eye_y + 8], fill=eye_color)
    draw.ellipse([left_eye_x - 4, eye_y - 4, left_eye_x + 4, eye_y + 4], fill="black")

    # 右目
    right_eye_x = center_x + 35
    draw.ellipse(
        [
            right_eye_x - eye_width // 2,
            eye_y - eye_height // 2,
            right_eye_x + eye_width // 2,
            eye_y + eye_height // 2,
        ],
        fill="white",
    )
    draw.ellipse(
        [right_eye_x - 8, eye_y - 8, right_eye_x + 8, eye_y + 8], fill=eye_color
    )
    draw.ellipse([right_eye_x - 4, eye_y - 4, right_eye_x + 4, eye_y + 4], fill="black")

    # 眉毛
    brow_y = eye_y - 20
    draw.ellipse(
        [left_eye_x - 15, brow_y - 3, left_eye_x + 15, brow_y + 3], fill="#654321"
    )
    draw.ellipse(
        [right_eye_x - 15, brow_y - 3, right_eye_x + 15, brow_y + 3], fill="#654321"
    )

    # 鼻
    nose_y = center_y + 10
    draw.ellipse(
        [center_x - 8, nose_y - 5, center_x + 8, nose_y + 5],
        fill=skin_tone,
        outline="#c0c0c0",
    )

    # 口
    mouth_y = center_y + 50
    draw.ellipse(
        [center_x - 20, mouth_y - 8, center_x + 20, mouth_y + 8], fill="#ff9999"
    )

    # 頬の色味（パーソナルカラーに応じて）
    cheek_color = skin_tone
    if "spring" in filename.lower():
        cheek_color = "#ffb3ba"  # 暖かいピンク
    elif "summer" in filename.lower():
        cheek_color = "#e6ccff"  # 涼しいピンク
    elif "autumn" in filename.lower():
        cheek_color = "#ffcc99"  # 暖かいオレンジ
    elif "winter" in filename.lower():
        cheek_color = "#ff99cc"  # 鮮やかなピンク

    # 左頬
    draw.ellipse(
        [center_x - 70, center_y + 10, center_x - 40, center_y + 40], fill=cheek_color
    )
    # 右頬
    draw.ellipse(
        [center_x + 40, center_y + 10, center_x + 70, center_y + 40], fill=cheek_color
    )

    # タイトルを下部に描画
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 20)
    except:
        font = ImageFont.load_default()

    title_bbox = draw.textbbox((0, 0), title, font=font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (size[0] - title_width) // 2
    draw.text((title_x, size[1] - 40), title, fill="black", font=font)

    img.save(filename, "JPEG", quality=90)
    print(f"生成完了: {filename}")


def create_blurry_face_image(filename, size=(512, 512)):
    """ぼやけた顔画像を生成"""
    from PIL import ImageFilter

    # まず普通の顔を作成
    create_face_image("#ffdbac", "#8b4513", "#654321", "Blurry Sample", filename, size)

    # 画像を読み込んでぼかし効果を適用
    img = Image.open(filename)
    img = img.filter(ImageFilter.GaussianBlur(radius=8))
    img.save(filename, "JPEG", quality=60)
    print(f"ぼかし効果適用完了: {filename}")


def create_no_face_landscape(filename, size=(512, 512)):
    """顔のない風景画像を生成"""
    img = Image.new("RGB", size, color="#87CEEB")  # スカイブルー
    draw = ImageDraw.Draw(img)

    # 地面
    draw.rectangle([0, size[1] * 3 // 4, size[0], size[1]], fill="#228B22")  # フォレストグリーン

    # 山
    mountain_points = [
        (0, size[1] * 3 // 4),
        (size[0] // 3, size[1] // 2),
        (size[0] * 2 // 3, size[1] * 3 // 4),
        (size[0], size[1] * 3 // 4),
    ]
    draw.polygon(mountain_points, fill="#696969")  # グレー

    # 太陽
    sun_x, sun_y = size[0] - 80, 60
    draw.ellipse(
        [sun_x - 25, sun_y - 25, sun_x + 25, sun_y + 25], fill="#FFD700"
    )  # ゴールド

    # 雲
    for i in range(3):
        cloud_x = 30 + i * 140
        cloud_y = 40 + i * 15
        for j in range(4):
            x = cloud_x + j * 12
            y = cloud_y + (j % 2) * 3
            draw.ellipse([x, y, x + 35, y + 20], fill="white")

    # 木
    tree_x, tree_y = 80, size[1] * 3 // 4
    draw.rectangle(
        [tree_x - 8, tree_y - 80, tree_x + 8, tree_y], fill="#8B4513"
    )  # サドルブラウン
    draw.ellipse(
        [tree_x - 25, tree_y - 100, tree_x + 25, tree_y - 40], fill="#228B22"
    )  # フォレストグリーン

    # タイトル
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 20)
    except:
        font = ImageFont.load_default()

    title = "No Face Sample"
    title_bbox = draw.textbbox((0, 0), title, font=font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (size[0] - title_width) // 2
    draw.text((title_x, size[1] - 40), title, fill="black", font=font)

    img.save(filename, "JPEG", quality=85)
    print(f"生成完了: {filename}")


def main():
    """メイン処理"""
    output_dir = "/Users/mahiguch/dev/personal-color/server/test_images"
    os.makedirs(output_dir, exist_ok=True)

    print("🎨 パーソナルカラー診断テスト用画像を生成中...")

    # Spring（スプリング）タイプ
    # 特徴: 明るく華やかな印象、イエローベースの肌、明るい髪色
    create_face_image(
        skin_tone="#ffdbac",  # 明るいイエローベースの肌
        hair_color="#daa520",  # ゴールデンロッド（明るい髪色）
        eye_color="#228b22",  # 明るいグリーン
        title="Spring Type Sample",
        filename=os.path.join(output_dir, "spring_sample.jpg"),
    )

    # Summer（サマー）タイプ
    # 特徴: 上品で涼しげな印象、ブルーベースの肌、ソフトな髪色
    create_face_image(
        skin_tone="#ffefd5",  # ピーチパフ（ブルーベースの肌）
        hair_color="#a0522d",  # シエナ（ソフトな髪色）
        eye_color="#4682b4",  # スチールブルー
        title="Summer Type Sample",
        filename=os.path.join(output_dir, "summer_sample.jpg"),
    )

    # Autumn（オータム）タイプ
    # 特徴: 深みのある暖かい印象、イエローベースの肌、深い髪色
    create_face_image(
        skin_tone="#deb887",  # バーリーウッド（深いイエローベース）
        hair_color="#8b4513",  # サドルブラウン（深い髪色）
        eye_color="#8b4513",  # サドルブラウン
        title="Autumn Type Sample",
        filename=os.path.join(output_dir, "autumn_sample.jpg"),
    )

    # Winter（ウィンター）タイプ
    # 特徴: はっきりと鮮やかな印象、ブルーベースの肌、コントラストの強い髪色
    create_face_image(
        skin_tone="#f5f5dc",  # ベージュ（クリアなブルーベース）
        hair_color="#2f4f4f",  # ダークスレートグレー（コントラストの強い髪色）
        eye_color="#191970",  # ミッドナイトブルー
        title="Winter Type Sample",
        filename=os.path.join(output_dir, "winter_sample.jpg"),
    )

    # エラーケース画像
    print("\n🔧 エラーケーステスト用画像を生成中...")

    # ぼやけた画像
    create_blurry_face_image(os.path.join(output_dir, "blurry_sample.jpg"))

    # 顔が写っていない画像
    create_no_face_landscape(os.path.join(output_dir, "no_face_sample.jpg"))

    print("\n✅ 全てのテスト用画像の生成が完了しました！")
    print(f"📁 出力先: {output_dir}")
    print("\n📊 生成された画像:")
    print("  🌸 spring_sample.jpg - スプリングタイプ")
    print("  🌊 summer_sample.jpg - サマータイプ")
    print("  🍂 autumn_sample.jpg - オータムタイプ")
    print("  ❄️ winter_sample.jpg - ウィンタータイプ")
    print("  😵‍💫 blurry_sample.jpg - ぼやけた画像（エラーテスト用）")
    print("  🏔️ no_face_sample.jpg - 顔なし画像（エラーテスト用）")


if __name__ == "__main__":
    main()
