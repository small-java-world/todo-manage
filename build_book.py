#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BOOTH販売用PDF作成スクリプト
1216x832の横長画像をそのままPDF化
"""

import os
import glob
from pathlib import Path
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.cidfonts import UnicodeCIDFont

# ========== 設定定数 ==========
SOURCE_DIR_MAIN = r"G:\GrudgeOfTheTranslucentBones\pixiv\共通素材\エロプレイ\アイテム23______\トウカイテイオー\png"
SOURCE_DIR_EXT = r"G:\GrudgeOfTheTranslucentBones\pixiv\共通素材\エロプレイ\アイテム23______\トウカイテイオー\png\ext"
OUTPUT_PDF = r"G:\GrudgeOfTheTranslucentBones\pixiv\共通素材\エロプレイ\アイテム23______\トウカイテイオー\png\booth_release_v1.pdf"

# 画像サイズ（ピクセル = ポイント）
PAGE_WIDTH = 1216
PAGE_HEIGHT = 832

# 表紙テキスト（後で編集可能）
AUTHOR_NAME = "Lumiere"
ACCOUNT_ID = "mumumu229748"
COPYRIGHT_TEXT = "※無断転載、複写、複製、配布などの行為を固く禁じます"

# 対象拡張子
VALID_EXTENSIONS = ('.png', '.jpg', '.jpeg')


def collect_images(directory):
    """
    指定ディレクトリ直下から画像ファイルを収集し、ファイル名昇順でソート
    """
    if not os.path.exists(directory):
        print(f"警告: ディレクトリが見つかりません: {directory}")
        return []

    images = []
    for ext in VALID_EXTENSIONS:
        images.extend(glob.glob(os.path.join(directory, f"*{ext}")))
        images.extend(glob.glob(os.path.join(directory, f"*{ext.upper()}")))

    # ファイル名でソート
    images = sorted(images, key=lambda x: os.path.basename(x).lower())

    # サブディレクトリを除外（直下のみ）
    images = [img for img in images if os.path.isfile(img)]

    return images


def create_cover_page(pdf_canvas):
    """
    表紙ページを作成
    cover_000.png が存在すればそれを使用、なければテキストベースの表紙を作成
    """
    cover_path = os.path.join(SOURCE_DIR_MAIN, "cover_000.png")

    if os.path.exists(cover_path):
        # cover_000.png が存在する場合はそれを使用
        print(f"表紙画像を使用: {cover_path}")
        pdf_canvas.drawImage(cover_path, 0, 0, width=PAGE_WIDTH, height=PAGE_HEIGHT)
    else:
        # テキストベースの表紙を作成
        print("表紙画像が見つからないため、テキストベースの表紙を作成")

        # 白背景
        pdf_canvas.setFillColorRGB(1, 1, 1)
        pdf_canvas.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=True, stroke=False)

        # 日本語フォントを登録
        try:
            pdfmetrics.registerFont(UnicodeCIDFont('HeiseiKakuGo-W5'))
            japanese_font = 'HeiseiKakuGo-W5'
        except:
            # フォールバック: HeiseiMin-W3を試す
            try:
                pdfmetrics.registerFont(UnicodeCIDFont('HeiseiMin-W3'))
                japanese_font = 'HeiseiMin-W3'
            except:
                # どちらも使えない場合はHelvetica
                japanese_font = 'Helvetica'

        # 黒文字で中央にテキストを配置
        pdf_canvas.setFillColorRGB(0, 0, 0)

        # テキストを中央に配置
        text_lines = [
            (f"Author: {AUTHOR_NAME}", "Helvetica", 20),
            (f"X(Twitter): @{ACCOUNT_ID}", "Helvetica", 20),
            ("", "Helvetica", 20),  # 空行
            (COPYRIGHT_TEXT, japanese_font, 16)
        ]

        # 中央揃えで描画
        y_start = PAGE_HEIGHT / 2 + 50
        line_height = 35

        for i, (line, font, size) in enumerate(text_lines):
            if line:  # 空行でなければ描画
                pdf_canvas.setFont(font, size)
                text_width = pdf_canvas.stringWidth(line, font, size)
                x = (PAGE_WIDTH - text_width) / 2
                y = y_start - (i * line_height)
                pdf_canvas.drawString(x, y, line)

    pdf_canvas.showPage()


def create_pdf():
    """
    PDFを作成するメイン関数
    """
    # 出力ディレクトリを作成
    output_dir = os.path.dirname(OUTPUT_PDF)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"出力ディレクトリを作成: {output_dir}")

    # 画像ファイルを収集
    print("\n画像ファイルを収集中...")
    images_main = collect_images(SOURCE_DIR_MAIN)
    images_ext = collect_images(SOURCE_DIR_EXT)

    # cover_000.png を除外（表紙として別途処理するため）
    images_main = [img for img in images_main
                   if not os.path.basename(img).lower().startswith('cover_000')]

    all_images = images_main + images_ext

    print(f"メインディレクトリ: {len(images_main)} 枚")
    print(f"extディレクトリ: {len(images_ext)} 枚")
    print(f"合計: {len(all_images)} 枚\n")

    if len(all_images) == 0:
        print("警告: 画像が見つかりませんでした")
        return

    # PDFキャンバスを作成
    print(f"PDF作成中: {OUTPUT_PDF}")
    pdf = canvas.Canvas(OUTPUT_PDF, pagesize=(PAGE_WIDTH, PAGE_HEIGHT))

    # 表紙ページを作成
    create_cover_page(pdf)

    # 各画像をページとして追加
    for idx, image_path in enumerate(all_images, start=1):
        try:
            print(f"処理中 [{idx}/{len(all_images)}]: {os.path.basename(image_path)}")

            # 画像をそのままのサイズで配置（左下が原点）
            pdf.drawImage(image_path, 0, 0, width=PAGE_WIDTH, height=PAGE_HEIGHT,
                         preserveAspectRatio=False)
            pdf.showPage()

        except Exception as e:
            print(f"エラー: {image_path} の処理に失敗しました: {e}")
            continue

    # PDFを保存
    pdf.save()
    print(f"\n完了! PDFを保存しました: {OUTPUT_PDF}")
    print(f"総ページ数: {len(all_images) + 1} ページ（表紙含む）")


if __name__ == "__main__":
    print("=" * 60)
    print("BOOTH販売用PDF作成スクリプト")
    print("=" * 60)
    create_pdf()
