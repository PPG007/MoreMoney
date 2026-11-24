#!/usr/bin/env bash
# MoreMoney 本地质量门禁（T24.4）。
# 用法：bash scripts/quality-gate.sh [--with-device]
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> 静态检查 + 编译 + JVM 单测 + Lint + AndroidTest 编译"
./gradlew :app:assembleDebug :app:testDebugUnitTest :app:lintDebug :app:compileDebugAndroidTestKotlin

echo "==> 红线检查"
bash scripts/check-redlines.sh

if [ "${1:-}" = "--with-device" ]; then
  echo "==> 设备 instrumentation"
  ./gradlew :app:connectedDebugAndroidTest
else
  echo "==> 跳过 instrumentation（追加 --with-device 且连接设备后运行）"
fi

echo "quality gate passed"
