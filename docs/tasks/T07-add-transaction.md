# T07 · 记一笔面板

> 状态：待开始 ｜ 优先级：P1 ｜ 依赖：T03、T04、T05 ｜ 预估：3.0 人日
> 设计依据：`设计规范.md` §8.2、§9.1、§9.2；截图 `03-add-light.png`、`04-add-calc-light.png`、`05-add-note-light.png`、`06-add-dark.png`

## 1. 目标

实现全屏“记一笔”：分类选择、账本/成员/日期选择、金额计算器、备注、保存。要求单手可完成，保存固定在金额行右侧。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/add/AddTxnPage.ets` | 页面容器、状态、保存流程 |
| `entry/src/main/ets/pages/add/CategoryPicker.ets` | 分类区（常用 + 分组 + 选中态） |
| `entry/src/main/ets/pages/add/CalcKeypad.ets` | 运算符列 + 数字键盘 |
| `entry/src/main/ets/pages/add/AmountRow.ets` | 金额显示、备注框、保存按钮 |
| `entry/src/main/ets/pages/add/NoteEditor.ets` | 展开式备注编辑器 |
| `entry/src/main/ets/pages/add/SelectorRow.ets` | 账本/成员/日期三选择器 |
| `entry/src/main/ets/components/sheet/BookPickerSheet.ets` | 账本选择弹层 |
| `entry/src/main/ets/components/sheet/MemberPickerSheet.ets` | 成员选择弹层（含“管理成员”入口） |
| `entry/src/main/ets/models/NavParams.ets` | `AddTxnParam`（若 T06 已建则复用） |

## 3. 页面结构

```text
NavDestination (hideTitleBar)
└── Column
    ├── 顶部 48：关闭 34 / “记一笔” 13 / “仅支出” 10
    ├── CategoryPicker (layoutWeight 1)
    ├── SelectorRow（36 高，三列）
    ├── AmountRow（金额 26 + 备注 38 + 保存 38）
    ├── CalcKeypad（1fr : 3fr，高约 186）
    └── 底部安全区占位
```

备注展开时：`NoteEditor` 覆盖在 `CalcKeypad` 上方（108 高），金额行与保存保持可见。

## 4. 实现要求

### 4.1 进入参数

```ts
const p = ctx.pathInfo.param;
if (p instanceof AddTxnParam) {
  this.initialBookId = p.bookId;
  this.dayKey = p.dayKey === '' ? DateUtil.dayKey(new Date()) : p.dayKey;
}
```

- 账本默认值优先级：入参 `bookId` > `SettingsService.defaultBookId` > 默认账本。
- 日期默认今天，允许选择过去任意日期，**禁止未来日期**（`DatePickerDialog` 设置 `end: new Date()`）。

### 4.2 分类区

- 数据：`CategoryDao.listGroups()` + `listByGroup()`；首组固定为“常用”，最多 8 个，排序按拼音（直接调用 T03 声明的 `CategoryDao.listFrequent`，T10 复用同一实现）。
- 结构：`List` + `ListItemGroup`（`.sticky(StickyStyle.Header)`）；每个 group 内放**一个** `ListItem`，该 ListItem 内是 `Flex({ wrap: FlexWrap.Wrap })`，每项 `width('25%')`（ListItemGroup 的直接子节点只能是 ListItem）。
- 组头：padding `8 2 6`，名称 11/700，右侧说明 10/400 `ink_3`（如“按使用频率”）。
- 分类按钮：最小高 78、padding `7 2`、圆角 16、图标 52×52（圆角 16，分类色 13% 底，图标 26）、名称 10/500 `ink_2`。
- 选中态：1vp `brand_ink` 边框 + `surface` 底 + 图标外 2vp `brand_soft` 环。
- 未选中的常用分类也显示，不因筛选隐藏。

### 4.3 选择器行

- 三列等分，高 36，圆角 10，1vp `line`，背景 `surface`，文字 10/500 `ink_2`，图标 12。
- 账本：显示封面 16 + 名称；必选。私密账本未解锁时先弹解锁（T13），解锁后才可选中。
- 成员：显示首字圆点 + 名称；默认成员为 `isDefault`；弹层底部有“管理成员” → `pushPathByName('MemberManage')`。
- 日期：显示 `11月9日`，点击 `DatePickerDialog.show({ start: new Date(2000,0,1), end: new Date(), selected: current })`。

### 4.4 金额行

- 金额文本 26/700，前缀 `¥`，始终非负；使用 `CalcEngine.expression` 原样显示（空时显示 `0`）。
- 下方预览 10/400：颜色 `ink_3`，失败时 `expense`；文案由 `CalcEngine.preview()` 提供。
- 备注框：高 38，flex 1，最小宽 72，圆角 10，1vp `line`，背景 `surface`；收起时显示“备注”或备注前 12 字。
- 保存按钮：38 高、圆角 11、`btn_bg`/`btn_fg`、12/700，图标 `ic_check` 14；不合法时 40% 透明且不可点。
- 点击备注框展开 `NoteEditor`；点击金额行/键盘/分类时收起。

### 4.5 键盘

- 布局：`Row` 左侧运算符列（宽约 88，5 键等分），右侧数字区 `Grid` 3 列 4 行。
- 运算符：`+`、`−`、`×`、`÷`、退格（图标 17）。运算符键 18/600，`brand_wash` 底、`brand_ink` 字；退格 `surface_2`/`ink_2`。
- 数字键：`7 8 9 / 4 5 6 / 1 2 3 / . 0 00`，42 高、圆角 11、17/600、`surface` 底、1vp `line`。
- 所有按键 `stateStyles` 按下态为 `surface_2`。
- 键位调用 `CalcEngine.appendDigit/appendOperator/backspace`，不自己拼接字符串。
- 长按退格：`CalcEngine.clear()`。

### 4.6 备注编辑器

- 高 108，padding 10，圆角 13，`surface` 底，`Shadow`。
- `TextArea` 高 62、圆角 9、10/500，`maxLength(100)`，占位“记点什么…”。
- 顶部小字“备注”+ 字数 `n/100`；右下“完成”按钮 10/600 `brand_ink`。
- 展开时系统键盘会弹出，需保证编辑器在键盘上方；收起时恢复计算器。
- 点击外部（分类/键盘/选择器）或按返回收起，不直接退出页面。

### 4.7 保存流程

1. `const r = engine.evaluate(); if (!r.ok) { SnackBarService.show(...); return; }`
2. 校验 `categoryId !== ''`、账本已选；分类未选时提示“请选择分类”。
3. 组装 `Txn`：`id = IdUtil.uuid()`、`occurredAt = DateUtil.parseDayKey(dayKey).getTime() + 当前时分秒`（保留“现在”的时间，日期用所选日）、`dayKey`、`createdAt/updatedAt = Date.now()`、`note.trim()`。
4. `await TxnDao.insert(txn)`。
5. `this.stack.pop()`；父页面通过 `onPop` 回调刷新。
6. 成功提示：`SnackBarService.show('已记一笔 ¥15.00 · 午餐')`，备注超过 12 字截断加 `…`，无备注不带 `·`。

### 4.8 放弃确认

- 有任意输入（分类/金额/备注变更）时点关闭或系统返回，弹 `AlertDialog`：“放弃这笔记录？”取消 / 放弃。
- 无输入直接关闭。
- 保存成功后不弹确认。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `03-add-light.png` 对齐；深色与 `06-add-dark.png` 对齐 | 截图比对 |
| AC-2 | 分类分组头滚动吸顶；4 列网格不错位；选中态符合 §8.2 | 真机操作 |
| AC-3 | 计算器：`12+3` 显示 `合计 ¥15.00`；`5−8`、`1÷0`、`0` 分别显示对应提示且保存禁用 | 真机逐项操作 |
| AC-4 | 优先级正确：`1+2×3` 预览 `¥7.00` | 真机 |
| AC-5 | 输入 `10÷3` 保存后金额为 333 分（¥3.33） | 保存后查列表金额 |
| AC-6 | 备注展开与 `05-add-note-light.png` 一致，金额行与保存仍可见，最多 100 字 | 截图 + 输入 |
| AC-7 | 日期可选过去任意一天，未来日期不可选 | DatePicker 验证 |
| AC-8 | 保存后返回首页，新记录出现在所选日期分组，分类/成员/备注正确 | 真机 |
| AC-9 | 关闭有输入的页面会二次确认；保存后关闭不确认 | 真机 |
| AC-10 | 私密账本未解锁时无法选中；T13 完成后点击应弹解锁，解锁后可正常记账 | 真机 + T13 |
| AC-11 | 构建通过 | `devecocli build` |

## 6. 注意事项

- 计算器是自定义键盘，页面内不得再出现系统数字键盘。
- 备注编辑器使用系统输入法，展开期间不要同时显示自定义键盘。
- `AddTxnParam` 必须是 class，接收端用 `instanceof`。
- 不要在此页面直接写 SQL 或聚合，全部走 DAO。
- 保存前必须确保 `amountCents > 0`，禁止负数和 0 入库。
