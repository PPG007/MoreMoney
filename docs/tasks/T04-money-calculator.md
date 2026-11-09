# T04 · 金额格式化与计算表达式引擎

> 状态：待开始 ｜ 优先级：P0 ｜ 依赖：T01 ｜ 预估：1.0 人日
> 设计依据：`设计规范.md` §9.1、§10.2

## 1. 目标

实现全项目唯一的金额工具与“记一笔”计算器引擎，纯函数、无 UI 依赖、可单测。UI 只负责把按键传给引擎并渲染结果。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/utils/MoneyUtil.ets` | 分 ↔ 元、千分位、格式化、四舍五入 |
| `entry/src/main/ets/utils/ExpressionEngine.ets` | 表达式状态机与求值 |
| `entry/src/main/ets/utils/CalcTypes.ets` | `CalcToken`、`CalcResult`、`CalcError` |
| `entry/src/test/ExpressionEngine.test.ets` | 单元测试（Hypium） |
| `entry/src/test/MoneyUtil.test.ets` | 单元测试 |

## 3. 实现要求

### 3.1 MoneyUtil

```ts
export function formatCents(cents: number, options?: MoneyFormatOptions): string
export function formatYuan(cents: number): string        // 不带 ¥，用于输入框
export function parseYuanToCents(text: string): number | null
export function roundHalfUp(value: number): number        // 用于最终取整
export function yuanTextToCents(text: string): number | null
```

规则：

- `formatCents(128640)` → `¥1,286.40`；`formatCents(128640, { symbol: false })` → `1,286.40`。
- 金额永远保留两位小数；千分位使用英文逗号。
- 负数：`−¥12.00`（使用 U+2212 `−`，不是连字符），仅展示层使用；存储始终为非负。
- `parseYuanToCents('12.3')` → `1230`；`'12.345'` → `null`（超过两位小数）；`'-1'` → `null`；`'abc'` → `null`；`''` → `null`；`'.5'` → `500`。
- 不使用 `toFixed` 做金额存储转换；只用整数运算。

### 3.2 表达式引擎

状态：

```ts
export class CalcEngine {
  expression: string;                 // 显示用，如 '12+3'
  appendDigit(d: string): void;       // '0'-'9'、'.'、'00'
  appendOperator(op: Operator): void; // '+' | '-' | '×' | '÷'
  backspace(): void;
  clear(): void;
  evaluate(): CalcResult;
  preview(): CalcPreview;             // { text: string; valid: boolean }
}
```

求值规则：

1. 只支持二元运算 `+ − × ÷`，无括号，无 `=`，无 `C`（`clear` 仅供内部/长按使用）。
2. 优先级：`× ÷` 高于 `+ −`；同级从左到右。
3. 内部不使用浮点：所有操作数以 **1e-6 元** 为最小单位（整数，scale = 1_000_000），最终结果四舍五入到分。
4. 输入限制：
   - 每个数字最多 2 位小数；第 3 位小数按键被忽略；
   - 单个数字整数部分最多 9 位；整个表达式最长 24 个字符；
   - 连续运算符：用新运算符替换最后一个（`1+×` → `1×`）；
   - 第二个小数点被忽略；
   - 以运算符开头时自动补 `0`（`×3` → `0×3`）。
5. 求值失败返回结构化错误，不抛异常：

```ts
export enum CalcError {
  NONE = 'none',
  EMPTY = 'empty',
  INVALID = 'invalid',
  ZERO = 'zero',
  NEGATIVE = 'negative',
  DIVIDE_BY_ZERO = 'divide_by_zero',
  TOO_LARGE = 'too_large'
}
export class CalcResult {
  ok: boolean = false;
  cents: number = 0;
  error: CalcError = CalcError.NONE;
}
```

6. 预览文案：
   - 合法且 > 0：`合计 ¥15.00`
   - 空表达式：`请输入金额`
   - 结果为 0：`金额需大于 0`
   - 负数：`金额不能为负`
   - 除零/非法：`无法计算`
7. 上限：最终 `cents ≤ 9_999_999_999`（¥99,999,999.99），超出返回 `TOO_LARGE`。

### 3.3 验收用例（必须全部写成单测）

| 输入 | 期望 |
|---|---|
| `12+3` | 1500 |
| `1+2×3` | 700 |
| `10−4` | 600 |
| `10÷4` | 250 |
| `10÷3` | 333 |
| `1÷3×3` | 100 |
| `0.1+0.2` | 30 |
| `12..3` | 1230（第二个小数点忽略） |
| `5−8` | NEGATIVE |
| `0` | ZERO |
| `1÷0` | DIVIDE_BY_ZERO |
| `3×` | INVALID |
| `999999.99×9` | 899999991（元 8,999,999.91） |
| 空表达式 | EMPTY |
| 退格删除 `12+` 的 `+` | `12` 且求值 1200 |
| `00` | ZERO |
| 连续按 `+` 再按 `×` | 表达式为 `0×`（替换） |

## 4. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 3.3 全部用例通过 | 运行 Local Unit Test，全绿 |
| AC-2 | 引擎无 UI/资源依赖，可被 Node 环境单测 | 检查 import |
| AC-3 | 同一表达式连续求值 100 次结果一致 | 单测循环断言 |
| AC-4 | 金额格式 `¥1,286.40`、`−¥12.00` 正确 | 单测断言字符串 |
| AC-5 | 构建通过 | `devecocli build` |

## 5. 注意事项

- 这是全项目唯一允许“做数学运算”的模块；页面不得自行 `Number(x) * 100`。
- 不要用 `eval`、`Function` 或 JSON 序列化求值。
- 运算符显示用 `×` `÷` `−`，内部 token 也用这三个字符，避免符号混用。
- 长按退格清空（`clear`）是唯一清空入口，设计稿无 C 键。
