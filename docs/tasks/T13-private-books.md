# T13 · 私密账本与解锁

> 状态：待开始 ｜ 优先级：P2 ｜ 依赖：T03、T05 ｜ 预估：2.5 人日
> 设计依据：`设计规范.md` §8.10、§9.4、§10.5；截图 `19-unlock-light.png`

## 1. 目标

实现私密账本的密码设置、验证、解锁会话、生物识别、打码与统计排除、防截屏。**本任务必须先于 T08 执行**，T08 的私密开关依赖本任务的密码与解锁组件。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/service/PrivateBookService.ets` | 密码哈希/验证/会话/锁定 ID |
| `entry/src/main/ets/utils/CryptoUtil.ets` | PBKDF2、随机盐、常量时间比较 |
| `entry/src/main/ets/components/sheet/UnlockSheet.ets` | 解锁弹层 |
| `entry/src/main/ets/components/sheet/PasswordSetupSheet.ets` | 设置/修改密码弹层 |
| `entry/src/main/ets/service/ScreenPrivacyService.ets` | 防截屏开关 |
| `entry/src/main/module.json5` | 声明 `ohos.permission.ACCESS_BIOMETRIC` |

## 3. 密码与密钥

导入来源：`userAuth` 来自 `@kit.UserAuthenticationKit`，`cryptoFramework` 来自 `@kit.CryptoArchitectureKit`，`util` 来自 `@kit.ArkTS`。

### 3.1 存储

- 只在 `book` 表存 `pwd_hash`（Base64）、`pwd_salt`（Base64）、`pwd_iter`（10000）。
- **禁止**存储明文、可逆密文或把密码写入 Preferences。
- 算法：PBKDF2-HMAC-SHA256，salt 16 字节随机，迭代 10000，输出 32 字节。

```ts
const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
const spec: cryptoFramework.PBKDF2Spec = {
  algName: 'PBKDF2',
  password: password,          // 直接传字符串，UTF-8
  salt: salt,                  // Uint8Array(16)
  iterations: 10000,
  keySize: 32
};
const secret = await kdf.generateSecret(spec);
```

- 随机数：`cryptoFramework.createRandom().generateRandomSync(16).data`。
- Base64：`util.Base64Helper`（`@kit.ArkTS`）。
- 比较：逐字节 XOR 累加，耗时与内容无关；不得用 `===` 比较哈希字符串。

### 3.2 PrivateBookService

```ts
export class PrivateBookService {
  static async setPassword(bookId: string, password: string): Promise<void>
  static async verify(bookId: string, password: string): Promise<boolean>
  static async changePassword(bookId: string, oldPwd: string, newPwd: string): Promise<boolean>
  static async clearPassword(bookId: string, password: string): Promise<boolean>
  static async isLocked(bookId: string): Promise<boolean>
  static async lockedBookIds(): Promise<string[]>       // 私密且当前会话未解锁
  static async privateBookIds(): Promise<string[]>
}
```

- `isLocked`：`book.isPrivate === true` 且 `!UiStore.instance().isBookUnlocked(bookId)`。
- 解锁：`ui.unlockBook(bookId, 5)`；会话内 5 分钟免验证，从解锁时刻起算，不随页面刷新续期。
- 应用退到后台超过 5 分钟或冷启动：全部锁定（`unlockedUntil` 不持久化，天然满足）。
- 密码校验连续失败 5 次：该账本锁定 30 秒（内存计数，重启清零），提示剩余秒数。

### 3.3 生物识别

- 直接使用 `userAuth.getUserAuthInstance(authParam, widgetParam)`，在 `on('result')` 中处理 `ResultCode`；能力不可用（未录入/不支持）时隐藏入口，不要依赖已变更的 `getAvailableStatus` 重载。
- `AuthParam`：`challenge` 用 16 字节随机数，`authType: [UserAuthType.FACE, UserAuthType.FINGERPRINT]`，`authTrustLevel: AuthTrustLevel.ATL3`。
- 结果码 `SUCCESS` → 调用 `ui.unlockBook(bookId, 5)`；取消/失败 → 回到密码输入，不弹二次系统框。
- 设备无生物识别能力：隐藏“使用指纹/面容解锁”入口，只留密码。
- 声明 `ohos.permission.ACCESS_BIOMETRIC`（`module.json5` 的 `requestPermissions`）。

## 4. 解锁弹层

`UnlockSheet` 以 `bindSheet` 或自定义底部弹层实现，规格 §8.10：

- 底部弹层，padding `24 21 26`，圆角 28，背景 `surface`。
- 锁图标 60×60（圆角 22，`brand_wash`/`brand_ink`）。
- 标题 19/700：`解锁「家庭」`；说明 10/400 `ink_3`：“请输入密码查看该账本”。
- 密码框：45 高、圆角 13、`surface_2`、`TextInput({ type: InputType.Password })`，最多 20 位。
- 按钮行：`1fr 1.5fr`，取消（次级）/ 解锁（主按钮，46 高）。
- 生物识别行：10/600 `brand_ink`，图标 17，可用时显示在按钮上方。
- 忘记密码：10/400 下划线，点击弹说明“密码无法恢复，请通过备份恢复或删除该账本”。
- 错误提示：密码错误时密码框下方 10/400 `expense`，输入框轻微抖动（可选）。
- 解锁成功：关闭弹层，回调 `onUnlocked(bookId)`。

`PasswordSetupSheet`：

- 标题“设置密码”/“修改密码”；两个输入框（新密码、确认密码；修改时多一个旧密码）。
- 规则：4–20 位，允许字母/数字/符号；两次不一致提示。
- 底部主按钮“保存”。
- 设置成功后不自动解锁，由调用方决定（T08 保存账本后进入解锁态）。

## 5. 打码与统计排除

1. `MoneyText` 使用 `locked` 参数；本任务在各调用处传入 `await PrivateBookService.isLocked(bookId)`（列表数据可在批量查询时一次性算出 `locked` 字段，避免逐行查询）。
2. 所有把流水聚合进“合计/预算/图表”的调用方，传入 `StatsFilter.excludeBookIds = await PrivateBookService.lockedBookIds()`：
   - 首页摘要（T06）
   - 预算页（T12）
   - 图表三页（T15–T17）
   - 导出（T19）
3. 锁定账本的流水行：金额打码；进度条、百分比隐藏。
4. 解锁后 5 分钟内所有页面同步显示；过期后下一次进入页面重新打码（通过 `ui.unlockVersion` 触发刷新）。

## 6. 防截屏

`ScreenPrivacyService`（`window` 来自 `@kit.ArkUI`）：

```ts
static async enable(): Promise<void>   // window.setWindowPrivacyMode(true)
static async disable(): Promise<void>
```

- 打开解锁弹层时开启；关闭弹层且当前页面不含已解锁私密账本内容时关闭。
- 进入账本管理、预算、图表等页面时，若存在已解锁私密账本，保持开启；离开这些页面统一关闭。
- 实现位置：`Index` 监听路由变化 + 页面 `onShown/onHidden`；避免每个页面重复写。
- 若设备不支持，捕获异常并降级（不阻断功能）。

## 7. 集成点

| 位置 | 行为 |
|---|---|
| 首页账本 chip（私密） | 点击先弹 `UnlockSheet`，成功后切换账本 |
| 记一笔账本选择器 | 选择私密账本前先解锁 |
| 账本管理卡片 | “解锁”按钮；解锁后显示金额/进度 |
| 预算页 | 锁定账本直接排除，不显示行 |
| 图表页 | 锁定账本从账本筛选中隐藏，统计排除 |
| 搜索页 | 结果排除锁定账本 |

## 8. 验收标准

> 说明：AC-6 的“首页摘要/预算合计/图表排除”依赖 T06/T12/T15 已接入；若这些页面尚未完成，先验证服务层 `lockedBookIds()` 与单页打码，整页口径在对应页面任务完成后补跑。

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 设置密码后 `book.pwd_hash` 为 Base64 哈希，库中无明文 | 查库/日志 |
| AC-2 | 正确密码解锁，错误密码提示且不进入 | 真机 |
| AC-3 | 解锁后 5 分钟内再次进入不要求密码；超过 5 分钟重新要求 | 真机等待/改系统时间不可用，可临时把 5 分钟改为 10 秒验证后改回 |
| AC-4 | 连续 5 次错误后锁定 30 秒并提示倒计时 | 真机 |
| AC-5 | 有生物识别设备时可用指纹/面容解锁；无能力时入口隐藏 | 真机 |
| AC-6 | 锁定账本金额/进度打码，且不计入首页摘要、预算合计、图表 | 真机 + 造数 |
| AC-7 | 修改密码需旧密码；关闭私密需密码 | 真机 |
| AC-8 | 解锁弹层显示时系统截屏被阻止（真机截图全黑或系统提示） | 真机截屏 |
| AC-9 | 忘记密码弹说明，明确不可恢复 | 真机 |
| AC-10 | 构建通过 | `devecocli build` |

## 9. 注意事项

- 不要自行实现加密算法；只用系统 `cryptoFramework`。
- 密码哈希计算是同步 GPU/CPU 密集操作，必须 `await` 异步接口，不要在主线程用 `*Sync`。
- `unlockedUntil` 只存在内存，不要持久化，避免“重启后仍是解锁态”。
- 一次性恢复码 v1 不做，UI 只给不可恢复说明。
- 防截屏开启会影响本应用自身截图测试，验证时注意关闭。
