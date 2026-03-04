#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Configuration
# -------------------------------
DIST_DIR="dist"
PDF_DIR="$DIST_DIR/pdfs"

# -------------------------------
# Cleanup old build
# -------------------------------
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$PDF_DIR"

# -------------------------------
# Loop over Lecture Markdown files
# -------------------------------
for file in Lecture-*.md; do
    [ -f "$file" ] || continue

    name=$(basename "$file" .md)
    echo "Processing lecture: $name"

    # -------------------------------
    # 1️⃣ Build HTML for GitHub Pages
    # -------------------------------
    pnpm slidev build "$file" --out "$DIST_DIR/$name" --base "./"

    # -------------------------------
    # 2️⃣ Export PDF from Markdown
    # -------------------------------
    pnpm slidev export "$file" \
        --format pdf \
        --timeout 180000 \
        --wait 10000 \
        --output "$PDF_DIR/$name.pdf"

    # -------------------------------
    # 3️⃣ Export PNG for thumbnail
    # -------------------------------
    pnpm slidev export "$file" \
        --format png \
        --timeout 180000 \
        --wait 10000 \
        --output "$DIST_DIR/$name"

    # Move first slide as thumbnail
    if [ -f "$DIST_DIR/$name/1.png" ]; then
        mv "$DIST_DIR/$name/1.png" "$DIST_DIR/$name/thumbnail.png"
    fi

    # Remove extra slides
    rm -f "$DIST_DIR/$name/"[0-9]*.png || true
done

# -------------------------------
# 4️⃣ Generate modern index.html
# -------------------------------
cat > "$DIST_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<title>$SUBJECT_NAME</title>
<style>
body { font-family: system-ui, sans-serif; padding: 40px; background: #f5f7fa; }
h1 { margin-bottom: 30px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 25px; }
.card { background: white; border-radius: 14px; padding: 15px; box-shadow: 0 6px 15px rgba(0,0,0,0.06); transition: transform 0.15s ease; }
.card:hover { transform: translateY(-4px); }
.card img { width: 100%; border-radius: 10px; margin-bottom: 12px; }
.card h3 { margin: 0 0 10px 0; }
.card a { text-decoration: none; color: #0070f3; margin-right: 12px; font-weight: 500; }
.card a:hover { text-decoration: underline; }
</style>
</head>
<body>
<h1>$SUBJECT_NAME</h1>
<div class="grid">
EOF

# Loop over built lectures to populate index
for dir in "$DIST_DIR"/*/; do
    name=$(basename "$dir")
    [ "$name" != "pdfs" ] || continue

    cat >> "$DIST_DIR/index.html" <<EOF
  <div class="card">
    <img src="./$name/thumbnail.png" alt="$name">
    <h3>$name</h3>
    <a href="./$name/">View Slides</a>
    <a href="./pdfs/$name.pdf" download>Download PDF</a>
  </div>
EOF
done

# Close HTML
cat >> "$DIST_DIR/index.html" <<EOF
</div>
</body>
</html>
EOF

echo "✅ Build complete! Output in $DIST_DIR"

git subtree push --prefix dist origin gh-pages
git checkout gh-pages
