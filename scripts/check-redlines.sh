#!/usr/bin/env bash
# 跨端数据与设计红线检查（T24.3）。失败即返回非 0。
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

check() {
  local title="$1"
  shift
  if "$@"; then
    echo "FAIL: $title"
    fail=1
  else
    echo "OK:   $title"
  fi
}

# 1. 组件中不允许写十六进制颜色（ui/theme 与 Palette 除外）。
if grep -rn --include='*.kt' 'Color(0x' app/src/main/kotlin | grep -v 'ui/theme/'; then
  echo "FAIL: 组件中出现硬编码十六进制颜色"
  fail=1
else
  echo "OK:   组件无硬编码十六进制颜色"
fi

# 2. 页面/UI 不允许直接写 SQL。
if grep -rn --include='*.kt' -E 'execSQL|SupportSQLiteDatabase' app/src/main/kotlin/com/github/ppg007/moremoney/ui app/src/main/kotlin/com/github/ppg007/moremoney/service 2>/dev/null; then
  echo "FAIL: UI/service 中出现直接 SQL"
  fail=1
else
  echo "OK:   UI/service 未直接写 SQL"
fi

# 3. 不申请 INTERNET 权限。
if grep -rn 'android.permission.INTERNET' app/src/main/AndroidManifest.xml 2>/dev/null; then
  echo "FAIL: Manifest 申请了 INTERNET"
  fail=1
else
  echo "OK:   Manifest 无 INTERNET"
fi

# 4. book 表不得包含私密列（只看属性/列名声明，忽略文档注释）。
if grep -rn -E 'val (isPrivate|pwdHash|pwdSalt|pwdIter)|columnName *= *"(is_private|pwd_hash|pwd_salt|pwd_iter)"' \
  app/src/main/kotlin/com/github/ppg007/moremoney/data/db/entity 2>/dev/null; then
  echo "FAIL: book Entity 出现私密列"
  fail=1
else
  echo "OK:   book Entity 无私密列"
fi

# 5. 备份不得生成 PRIVATE 段。
if grep -rn '"PRIVATE"' app/src/main/kotlin | grep -v 'BackupFormat.kt' | grep -v 'BackupService.kt'; then
  echo "FAIL: 备份链路出现 PRIVATE 生成逻辑"
  fail=1
else
  echo "OK:   备份链路不生成 PRIVATE"
fi

exit "$fail"
