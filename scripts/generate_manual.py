#!/usr/bin/env python3

import anthropic
import base64
import pathlib
import os

client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

SCREENSHOTS_DIR = pathlib.Path(__file__).parent.parent / "docs" / "screenshots"
DOCS_DIR = pathlib.Path(__file__).parent.parent / "docs" / "manual"
DOCS_DIR.mkdir(parents=True, exist_ok=True)

screens = [
    ("screen_01", "メイン画面"),
]

for screen_id, screen_name in screens:
    img_path = SCREENSHOTS_DIR / f"{screen_id}.png"
    if not img_path.exists():
        print(f"⚠️  {img_path} が見つかりません。スキップします。")
        continue

    print(f"📖 {screen_name} のマニュアルを生成中...")
    img_data = base64.b64encode(img_path.read_bytes()).decode()

    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1500,
        messages=[{
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/png",
                        "data": img_data
                    }
                },
                {
                    "type": "text",
                    "text": f"""このiOSアプリ「ClimbLog（クライミング記録アプリ）」の{screen_name}のスクリーンショットを見て、
日本語でユーザー向けマニュアルをMarkdown形式で書いてください。

以下の構成で書いてください：
- 画面の概要（1〜2文）
- 主要な機能・UI要素の説明（箇条書き）
- 基本的な操作方法
- ヒントや注意事項（あれば）

スクリーンショットに見えるUI要素を具体的に説明してください。"""
                }
            ]
        }]
    )

    manual_text = response.content[0].text
    md_path = DOCS_DIR / f"{screen_id}.md"
    md_path.write_text(manual_text, encoding="utf-8")
    print(f"✅ {md_path} に保存しました")

print("\n🎉 マニュアル生成完了！")
