# T21 · 备份与恢复

> 状态：待开始 ｜ 优先级：P3 ｜ 依赖：T03、T13 ｜ 预估：2.5 人日
> 设计依据：`设计规范.md` §8.8、§10.5

## 1. 目标

实现本地备份包的导出与恢复：普通账本明文、私密账本独立密钥加密、带版本与校验和、恢复前预览并二次确认。v1 不做云同步、不做后台自动备份。

## 2. 交付物

| 路径 | 内容 |
|---|---|
| `entry/src/main/ets/service/BackupFormat.ets` | 包序列化/反序列化、校验和（纯函数） |
| `entry/src/main/ets/service/BackupService.ets` | 导出、恢复、加密/解密 |
| `entry/src/main/ets/utils/CryptoUtil.ets` | 复用 T13 的 PBKDF2 + AES-GCM 封装 |
| `entry/src/main/ets/components/sheet/RestorePreviewSheet.ets` | 恢复预览与私密密码输入 |
| `entry/src/test/BackupFormat.test.ets` | 往返与校验和单测 |

## 3. 备份包格式

导入来源：`cryptoFramework` 来自 `@kit.CryptoArchitectureKit`，`picker`/`fileIo` 来自 `@kit.CoreFileKit`，`util` 来自 `@kit.ArkTS`。

**有意不使用 JSON**：ArkTS 禁止 `as` 与动态属性访问，JSON 反序列化需要绕行；行式文本格式可确定性序列化、逐行校验、易于计算校验和。

文件名：`MoreMoney_YYYYMMDD_HHmm.mmbk`，UTF-8 文本。

```text
MOREMONEY_BACKUP
format=1
schemaVersion=1
createdAt=1762656000000
appVersion=1.0.0
books=3
members=3
categories=10
txns=128
budgets=2
privateBooks=1
checksum=<sha256 hex>
[BODY]
BOOK\t<b64(id)>\t<b64(name)>\t<b64(icon)>\t<b64(color)>\t<isPrivate>\t<b64(pwdHash)>\t<b64(pwdSalt)>\t<iter>\t<isDefault>\t<sort>\t<archived>\t<createdAt>\t<updatedAt>
MEMBER\t...
GROUP\t...
CATEGORY\t...
TXN\t<b64(id)>\t<b64(bookId)>\t<b64(categoryId)>\t<b64(memberId)>\t<amountCents>\t<occurredAt>\t<b64(dayKey)>\t<b64(note)>\t<createdAt>\t<updatedAt>
BUDGET\t...
PRIVATE\t<b64(bookId)>\t<b64(kdfSalt)>\t<b64(iv)>\t<b64(tag)>\t<b64(cipher)>
[END]
```

规则：

1. 所有字符串字段 Base64（UTF-8），避免 tab/换行污染；数字字段十进制。
2. `TXN` 只包含非私密账本的流水；私密账本的流水序列化为同样的 `TXN` 行文本，整体加密后放入一条 `PRIVATE` 记录。
3. `PRIVATE.cipher` 明文 = 该账本全部 `TXN` 行的 UTF-8 字节（行间 `\n`，末尾无换行）。
4. `checksum` = `SHA-256(`[BODY]` 与 `[END]` 之间的全部文本，UTF-8)`，小写 hex。
5. `schemaVersion` 必须为 1；更高版本拒绝恢复并提示升级应用。
6. 私密账本的书名、图标、颜色保持明文（设计允许显示名称），金额与备注加密。

## 4. 加密

- 口令派生：PBKDF2-HMAC-SHA256，salt 16 字节，迭代 10000，输出 32 字节。
- 对称加密：AES-256-GCM，IV 12 字节，AuthTag 16 字节；AAD 为空。
- API：`cryptoFramework.createCipher('AES256|GCM|NoPadding')`，密钥由 `createSymKeyGenerator('AES256')` 导入；参数结构以 SDK 为准。
- 每个私密账本独立 salt/iv/key；**不使用同一把全局密钥**。
- 恢复时必须逐本输入密码；密码错误 → 该账本恢复失败，整体中止（不写入半套数据）。

## 5. 导出流程

1. 数据与备份页点击“立即备份”。
2. 若存在锁定的私密账本：要求先解锁或输入密码（设计 §9.4：备份需要重新确认）。
3. 查询全部业务表 → 构建包文本 → 计算校验和。
4. `DocumentViewPicker.save` 选择位置 → 写入。
5. 成功后更新 `SettingsService.lastBackupAt` 与 `lastBackupPath`，刷新备份状态卡。
6. 失败/取消：对应提示；不更新状态。

## 6. 恢复流程

1. `DocumentViewPicker.select` 选择 `.mmbk` 文件（限制后缀）。
2. 读取文本 → 校验头、`format`、`schemaVersion`、`checksum`。
3. 解析计数与实体列表，构建预览：
   - 账本数、流水数、成员数、分类数、预算数、文件创建时间；
   - 私密账本列表（需要密码）。
4. 用户输入每个私密账本密码 → 解密 → 解析 `TXN` 行；失败则中止。
5. 二次确认：`AlertDialog`“恢复会覆盖当前全部数据，且不可撤销”。
6. 事务写入：
   - 清空 `book/member/category_group/category/txn/budget`；
   - 按包内顺序插入；
   - 重建默认账本唯一约束（包内已保证）。
   - 任一失败 → 回滚，保留原数据。
7. 成功后：`ui.lockAllPrivate()`、刷新所有页面、`SnackBar`“已恢复 N 笔记录”。

## 7. 校验与容错

- 校验和不匹配：拒绝恢复，提示“备份文件已损坏或被修改”。
- 未知行类型：忽略该行并记录告警（不阻断，便于向前兼容）。
- 重复主键：后出现的覆盖先出现的（仅包内重复，属异常），并记入预览告警。
- 缺少默认账本：把 `sort` 最小的账本设为默认。
- 恢复后 `seed_version` 保持不变，避免再次插入基线数据。

## 8. 备份状态

`SettingsService` 增加：

| key | 类型 |
|---|---|
| `lastBackupAt` | number |
| `lastBackupPath` | string |

数据页显示：`上次备份：11月9日 15:30` / `从未备份`；路径只显示文件名，避免泄露完整路径。

## 9. 验收标准

| 编号 | 验收项 | 验证方式 |
|---|---|---|
| AC-1 | 导出→删除数据→恢复，账本/成员/分类/流水/预算数量与金额完全一致 | 真机往返 |
| AC-2 | 校验和被篡改后拒绝恢复 | 手工改一个字符 |
| AC-3 | 私密账本密码正确才可恢复；错误密码整体中止且原数据不变 | 真机 |
| AC-4 | 私密账本的金额/备注在文件中不可见（密文） | 文本查看 |
| AC-5 | 恢复前必须二次确认；取消不写库 | 真机 |
| AC-6 | 恢复过程异常回滚，原数据保留 | 异常注入/代码审查 |
| AC-7 | 恢复后所有页面数据刷新，私密账本重新锁定 | 真机 |
| AC-8 | 备份状态卡显示上次备份时间，重启后保留 | 真机 |
| AC-9 | 取消文件选择不报错 | 真机 |
| AC-10 | 构建通过 | `devecocli build` |

## 10. 注意事项

- 不要在备份中存密码哈希之外的任何凭据；恢复私密账本必须重新输入密码。
- 加密只覆盖私密账本流水；普通账本按设计明文。
- 备份包不包含 `app_meta`、`Preferences`（设置项不迁移）。
- 恢复是破坏性操作，任何一步失败都必须整体回滚。
- 备份写入与恢复读取都走异步文件 API，禁止同步大文件读写。
