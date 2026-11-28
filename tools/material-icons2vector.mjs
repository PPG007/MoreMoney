#!/usr/bin/env node
// 把 Google Material Icons (Outlined, 24x24) SVG 转换为 Android VectorDrawable。
//
// 用法：
//   node tools/material-icons2vector.mjs <svg 源目录> <输出目录> [文件名...]
//
// 与 tools/svg2vector.mjs 的差异：
// - 跳过 fill="none" 的占位 path（Material 图标常带一个 24x24 的透明底）；
// - 支持 simple <circle> / <rect>（填充图形），转换为等价 pathData；
// - 输出头标注 Material Icons 来源与 Apache License 2.0。
//
// 只处理 24x24 单色图标；颜色统一为 #FF000000，由 Compose Icon 的 tint 着色。

import { readFileSync, writeFileSync, readdirSync, mkdirSync } from 'node:fs';
import { basename, join } from 'node:path';

const [srcDir, outDir, ...explicit] = process.argv.slice(2);
if (!srcDir || !outDir) {
  console.error('usage: node tools/material-icons2vector.mjs <svgDir> <outDir> [file...]');
  process.exit(1);
}

const files = explicit.length > 0 ? explicit : readdirSync(srcDir).filter((name) => name.endsWith('.svg'));
mkdirSync(outDir, { recursive: true });

let converted = 0;
for (const file of files) {
  const svgPath = join(srcDir, file);
  const svg = readFileSync(svgPath, 'utf8');
  const elements = [...svg.matchAll(/<(path|circle|rect)\b([^>]*?)\/?>/g)];
  const body = elements
    .map(([, tag, attrs]) => {
      if (attr(attrs, 'fill') === 'none' || attr(attrs, 'style').includes('fill:none')) {
        return '';
      }
      const evenOdd = attr(attrs, 'fill-rule') === 'evenodd';
      if (tag === 'path') {
        const d = attr(attrs, 'd');
        return d ? pathLine(d, evenOdd) : '';
      }
      if (tag === 'circle') {
        const cx = num(attr(attrs, 'cx'));
        const cy = num(attr(attrs, 'cy'));
        const r = num(attr(attrs, 'r'));
        if (r <= 0) {
          return '';
        }
        const d =
          'M' + fmt(cx - r) + ',' + fmt(cy) +
          'a' + fmt(r) + ',' + fmt(r) + ' 0 1,0 ' + fmt(r * 2) + ',0' +
          'a' + fmt(r) + ',' + fmt(r) + ' 0 1,0 ' + fmt(-r * 2) + ',0Z';
        return pathLine(d, false);
      }
      const x = num(attr(attrs, 'x'));
      const y = num(attr(attrs, 'y'));
      const width = num(attr(attrs, 'width'));
      const height = num(attr(attrs, 'height'));
      if (width <= 0 || height <= 0) {
        return '';
      }
      const d = 'M' + fmt(x) + ',' + fmt(y) + 'h' + fmt(width) + 'v' + fmt(height) + 'h' + fmt(-width) + 'Z';
      return pathLine(d, false);
    })
    .filter((line) => line.length > 0)
    .join('\n');
  if (!body) {
    console.warn('skip (no filled shape): ' + file);
    continue;
  }

  const vector =
    '<?xml version="1.0" encoding="utf-8"?>\n' +
    '<!-- 自动生成，勿手改：Google Material Icons Outlined（Apache License 2.0），' +
    '由 tools/material-icons2vector.mjs 从 ' + file + ' 转换 -->\n' +
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

function pathLine(d, evenOdd) {
  const fillType = evenOdd ? ' android:fillType="evenOdd"' : '';
  return '    <path\n        android:fillColor="#FF000000"' +
    ' android:pathData="' + d + '"' + fillType + ' />';
}

function attr(attrs, name) {
  const match = attrs.match(new RegExp(name + '="([^"]*)"'));
  return match ? match[1] : '';
}

function num(value) {
  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function fmt(value) {
  return String(Math.round(value * 1000) / 1000);
}
