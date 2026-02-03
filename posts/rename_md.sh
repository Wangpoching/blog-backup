#!/bin/bash

DIR="."  # 目標資料夾，可改

for file in "$DIR"/*.md; do
  [ -f "$file" ] || continue

  # 找第一個出現 title: 的行
  first_title=$(grep -m 1 '^title:' "$file")

  if [ -n "$first_title" ]; then
    # 取冒號後的文字，去掉前後空格
    title=$(echo "$first_title" | sed 's/^title:[[:space:]]*//')

    # 避免檔名有不合法字元
    title=$(echo "$title" | tr '/' '-' | tr '\\' '-' )

    new_file="$DIR/$title.md"

    # 如果新檔名跟舊檔名不同才改
    if [ "$file" != "$new_file" ]; then
      mv "$file" "$new_file"
      echo "Renamed '$file' → '$new_file'"
    fi
  fi
done

