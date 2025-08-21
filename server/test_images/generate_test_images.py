#!/usr/bin/env python3
"""
パーソナルカラー診断テスト用画像生成スクリプト
"""

from PIL import Image, ImageDraw, ImageFont
import os


def create_color_palette_image(colors, title, filename, size=(512, 512)):
    """カラーパレット画像を生成"""
    img = Image.new("RGB", size, color="white")
    draw = ImageDraw.Draw(img)

    # タイトルエリア
    title_height = 60
    draw.rectangle([0, 0, size[0], title_height], fill="#f0f0f0")

    # タイトルを描画（フォントがない場合はデフォルト）
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 24)
    except:
        font = ImageFont.load_default()

    title_bbox = draw.textbbox((0, 0), title, font=font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (size[0] - title_width) // 2
    draw.text((title_x, 20), title, fill="black", font=font)

    # カラーパレット描画
    palette_area = size[1] - title_height
    colors_per_row = 3
    rows = (len(colors) + colors_per_row - 1) // colors_per_row

    color_width = size[0] // colors_per_row
    color_height = palette_area // rows

    for i, color in enumerate(colors):
        row = i // colors_per_row
        col = i % colors_per_row

        x1 = col * color_width
        y1 = title_height + row * color_height
        x2 = x1 + color_width
        y2 = y1 + color_height

        draw.rectangle([x1, y1, x2, y2], fill=color)

    img.save(filename, "JPEG", quality=90)
    print(f"生成完了: {filename}")


def create_blurry_image(filename, size=(512, 512)):
    """ぼやけた画像を生成"""
    from PIL import ImageFilter

    # カラフルな模様を作成
    img = Image.new("RGB", size, color="white")
    draw = ImageDraw.Draw(img)

    # ランダムな円を描画
    import random

    for _ in range(20):
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        r = random.randint(20, 100)
        color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    # ぼかし効果を適用
    img = img.filter(ImageFilter.GaussianBlur(radius=10))
    img.save(filename, "JPEG", quality=60)
    print(f"生成完了: {filename}")


def create_no_face_image(filename, size=(512, 512)):
    """顔のない画像（風景）を生成"""
    img = Image.new("RGB", size, color="skyblue")
    draw = ImageDraw.Draw(img)

    # 空と地面
    draw.rectangle([0, size[1] // 2, size[0], size[1]], fill="green")

    # 太陽
    sun_x, sun_y = size[0] - 100, 80
    draw.ellipse([sun_x - 30, sun_y - 30, sun_x + 30, sun_y + 30], fill="yellow")

    # 雲
    for i in range(3):
        cloud_x = 50 + i * 150
        cloud_y = 60 + i * 20
        for j in range(4):
            x = cloud_x + j * 15
            y = cloud_y + (j % 2) * 5
            draw.ellipse([x, y, x + 40, y + 25], fill="white")

    # 木
    tree_x, tree_y = 100, size[1] // 2
    draw.rectangle([tree_x - 10, tree_y, tree_x + 10, tree_y + 100], fill="brown")
    draw.ellipse([tree_x - 40, tree_y - 40, tree_x + 40, tree_y + 20], fill="darkgreen")

    img.save(filename, "JPEG", quality=85)
    print(f"生成完了: {filename}")


def main():
    """メイン処理"""
    # 出力ディレクトリの作成
    output_dir = "/Users/mahiguch/dev/personal-color/server/test_images"
    os.makedirs(output_dir, exist_ok=True)

    # Spring（スプリング）タイプのカラーパレット
    spring_colors = [
        "#FFE4B5",  # 明るいベージュ
        "#FFD700",  # ゴールド
        "#98FB98",  # ライトグリーン
        "#FFA07A",  # ライトサーモン
        "#87CEEB",  # スカイブルー
        "#DDA0DD",  # プラム
        "#F0E68C",  # カーキ
        "#FFB6C1",  # ライトピンク
        "#20B2AA",  # ライトシーグリーン
    ]

    # Summer（サマー）タイプのカラーパレット
    summer_colors = [
        "#E6E6FA",  # ラベンダー
        "#B0C4DE",  # ライトスチールブルー
        "#F0F8FF",  # アリスブルー
        "#FFE4E1",  # ミスティローズ
        "#E0FFFF",  # ライトシアン
        "#D8BFD8",  # シスル
        "#F5F5DC",  # ベージュ
        "#FAFAD2",  # ライトゴールデンロッド
        "#E6E6FA",  # ラベンダー
    ]

    # Autumn（オータム）タイプのカラーパレット
    autumn_colors = [
        "#8B4513",  # サドルブラウン
        "#CD853F",  # ペルー
        "#D2691E",  # チョコレート
        "#A0522D",  # シエナ
        "#B8860B",  # ダークゴールデンロッド
        "#DAA520",  # ゴールデンロッド
        "#228B22",  # フォレストグリーン
        "#8B0000",  # ダークレッド
        "#800080",  # パープル
    ]

    # Winter（ウィンター）タイプのカラーパレット
    winter_colors = [
        "#000000",  # ブラック
        "#FFFFFF",  # ホワイト
        "#FF0000",  # レッド
        "#0000FF",  # ブルー
        "#800080",  # パープル
        "#FF69B4",  # ホットピンク
        "#00CED1",  # ダークターコイズ
        "#C0C0C0",  # シルバー
        "#4B0082",  # インディゴ
    ]

    # カラーパレット画像を生成
    create_color_palette_image(
        spring_colors,
        "Spring Type Colors",
        os.path.join(output_dir, "spring_sample.jpg"),
    )

    create_color_palette_image(
        summer_colors,
        "Summer Type Colors",
        os.path.join(output_dir, "summer_sample.jpg"),
    )

    create_color_palette_image(
        autumn_colors,
        "Autumn Type Colors",
        os.path.join(output_dir, "autumn_sample.jpg"),
    )

    create_color_palette_image(
        winter_colors,
        "Winter Type Colors",
        os.path.join(output_dir, "winter_sample.jpg"),
    )

    # エラーケース画像を生成
    create_blurry_image(os.path.join(output_dir, "blurry_sample.jpg"))
    create_no_face_image(os.path.join(output_dir, "no_face_sample.jpg"))

    print("\n✅ 全てのテスト用画像の生成が完了しました！")
    print(f"出力先: {output_dir}")


if __name__ == "__main__":
    main()
