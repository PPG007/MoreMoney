# T10 · 分类管理

> 状态：已完成 ｜ 优先级：P1 ｜ 依赖：T03、T05 ｜ 预估：1.5 人日
> 设计依据：`设计规范.md` §8.6、§10.4、§2.5；截图 `15-categories-light.png`

## 1. 目标

实现分类分组与分类的管理，并落地“常用 = 按使用频率取前 N、组内按拼音排序”的规则。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/pages/categories/CategoryManagePage.ets` | 页面 |
| `entry/src/main/ets/pages/categories/FrequentCard.ets` | 常用卡 |
| `entry/src/main/ets/pages/categories/GroupCard.ets` | 分组卡 |
| `entry/src/main/ets/pages/categories/CategoryEditSheet.ets` | 新建/编辑分类 |
| `entry/src/main/ets/pages/categories/GroupEditSheet.ets` | 新建/重命名分组 |
| `entry/src/main/ets/utils/PinyinUtil.ets` | 汉字转拼音排序键 |
| `entry/src/main/ets/service/CategoryService.ets` | 常用计算、引用检查 |

## 3. 页面结构

```text
NavDestination
├── PageHeader（返回 / “分类管理” / 右侧“编辑”）
└── Scroll
    ├── 常用卡：标题 + badge“动态” + chips 流式布局
    ├── GroupCard × N：名称 + 数量 + 编辑；chips；末尾“＋ 新建分类”
    └── “＋ 新建分组”
```

## 4. 实现要求

### 4.1 常用卡

- 数据源：`CategoryService.listFrequent(8, 最近 30 天)`：
  1. 统计 `txn` 中 `deleted_at IS NULL` 且 `day_key >= 30 天前` 的分类使用次数；
  2. 次数降序；
  3. 次数相同按 `pinyin` 升序；
  4. 过滤 `archived=1`；
  5. 不足 8 个时用其余分类按拼音补齐。
- 卡片：padding 14、圆角 20、`surface` 底；标题 12/700 + badge 10/600“动态”。
- chips：图标 21、文字 10/500、胶囊背景 `surface_2`，间距 8。

### 4.2 分组卡

- 分组头：名称 12/700、数量 10/400 `ink_3`、右侧“编辑”10/600 `brand_ink`。
- chips 流式布局（`Flex wrap`，间距 8）：图标 19 + 名称 10/500；背景 `surface_2`，圆角 999。
- 末尾“＋”新建 chip：虚线边框 `line`、`ink_3`。
- 卡片 padding 13、圆角 18、间距 8。

### 4.3 编辑模式

- 页面头部“编辑”切换为“完成”。
- 编辑态下：每个分类 chip 右上角出现 12 的删除角标；分组头出现重命名/删除图标。
- 系统分组（`is_system=1`）可重命名，不可删除；自定义分组可删除，但组内仍有分类时拒绝并提示先移动/归档。
- 分类删除规则：
  - 被流水引用 → 只能归档（`archived=1`），归档后不出现在记账选择器，但历史流水正常显示；
  - 无引用 → 直接删除，二次确认。

### 4.4 新建/编辑分类

`bindSheet`：

| 字段 | 规则 |
|---|---|
| 名称 | 必填，1–8 字 |
| 分组 | 从现有分组中单选，默认当前分组 |
| 图标 | 13 个分类图标网格，44 方块，选中 `brand_ink` 边 |
| 颜色 | 图表 5 色 + c6/c7/c8 共 8 色，选中打勾 |

- 保存时计算 `pinyin`（见 4.5），新分类 `sort = max(sort)+1`。
- 编辑时若分类被引用，允许改名/换图标/换色，不重建 ID。

### 4.5 拼音排序键

```ts
export function pinyinKey(name: string): string {
  const t = i18n.Transliterator.getInstance('Han-Latin');
  return t.transform(name).toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')  // 去声调
    .replace(/[^a-z0-9]/g, '');
}
```

- `i18n` 从 `@kit.LocalizationKit` 导入。
- 纯英文/数字名直接返回小写字母数字。
- 转写失败（空串）时回退为名称本身的小写形式。
- 拼音键在分类新建/改名时写入 `category.pinyin`；不在查询时实时计算。

### 4.6 新建/重命名分组

- 分组名 1–6 字；新建 `is_system=0`，`sort = max+1`。
- 重命名不允许为空；系统分组允许改名。
- 分组名重复时提示但允许保存。

## 5. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 视觉与 `15-categories-light.png` 对齐 | 截图比对 |
| AC-2 | 常用卡最多 8 个，按近 30 天使用次数排序；次数相同按拼音 | 造数据验证 |
| AC-3 | 新建分类后立即出现在对应分组与记一笔页 | 真机 |
| AC-4 | 分类改名/换图标/换色后，历史流水同步更新样式 | 真机 |
| AC-5 | 被引用的分类只能归档；归档后记一笔不可选，历史记录仍显示 | 真机 |
| AC-6 | 无引用分类可删除；系统分组不可删除；自定义空分组可删除 | 真机 |
| AC-7 | 拼音排序：`餐饮(canyin)` 在 `出行(chuxing)` 前；英文分类按字母序 | 真机/单测 |
| AC-8 | 编辑模式切换正常，退出后角标消失 | 真机 |
| AC-9 | 构建通过 | `devecocli build` |

## 6. 注意事项

- “常用”是视图，不是分组表里的真实记录；不要往 `category_group` 插入“常用”。
- 拼音排序键必须在写入时固化，否则每次查询都要转写，性能差。
- 分类只能归档不能硬删（有引用时），这是数据完整性红线。
- 分类图标只允许使用 T01 清单中的 `ic_cat_*`。
