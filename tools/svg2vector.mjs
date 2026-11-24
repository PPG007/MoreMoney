#!/usr/bin/env node
// 把鸿蒙版 24x24 单色 SVG 图标批量转换为 Android VectorDrawable。
//
// 用法：
//   node tools/svg2vector.mjs <svg 源目录> <输出目录> [文件名...]
//
// 规则（与 WBS T01.4 一致）：
// - width/height = 24dp，viewport = 24
// - pathData 原样保留
// - fillColor 统一 #FF000000，由 Compose Icon 的 tint 着色
// - SVG 带 fill-rule="evenodd" 时输出 fillType="evenOdd"
// - 输出文件头标注“自动生成，勿手改”
//
// 目录与文件名都通过参数传入，脚本不读取自身目录下的输入文件。

import { readFileSync, writeFileSync, readdirSync, mkdirSync } from 'node:fs';
import { basename, join } from 'node:path';

const [srcDir, outDir, ...explicit] = process.argv.slice(2);
if (!srcDir || !outDir) {
  console.error('usage: node tools/svg2vector.mjs <svgDir> <outDir> [file...]');
  process.exit(1);
}

const files = explicit.length > 0 ? explicit : readdirSync(srcDir).filter((name) => name.endsWith('.svg'));
mkdirSync(outDir, { recursive: true });

let converted = 0;
for (const file of files) {
  const svgPath = join(srcDir, file);
  const svg = readFileSync(svgPath, 'utf8');
  const paths = [...svg.matchAll(/<path\b([^>]*)>/g)].map((m) => m[1]);
  if (paths.length === 0) {
    console.warn('skip (no path): ' + file);
    continue;
  }
  const body = paths
    .map((attrs) => {
      const d = attr(attrs, 'd');
      if (!d) {
        return '';
      }
      const evenOdd = attr(attrs, 'fill-rule') === 'evenodd';
      const fillType = evenOdd ? ' android:fillType="evenOdd"' : '';
      return '    <path\n        android:fillColor="#FF000000"' +
        ' android:pathData="' + d + '"' + fillType + ' />';
    })
    .filter((line) => line.length > 0)
    .join('\n');

  const vector = '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<!-- 自动生成，勿手改：tools/svg2vector.mjs 由 ' + file + ' 转换 -->\n' +
    '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n' +
    '    android:width="24dp"\n' +
    '    android:height="24dp"\n' +
    '    android:viewportWidth="24"\n' +
    '    android:viewportHeight="24">\n' +
    body + '\n' +
    '</vector>\n';

  const target = join(outDir, basename(file).replace(/\.svg$/, '.xml'));
  writeFileSync(target, vector, 'utf8');
  converted += 1;
}
console.log('converted ' + converted + ' icon(s) into ' + outDir);

function attr(attrs, name) {
  const match = attrs.match(new RegExp(name + '="([^"]*)"'));
  return match ? match[1] : '';
}
