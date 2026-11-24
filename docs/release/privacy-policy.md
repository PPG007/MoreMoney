# MoreMoney 隐私政策

- 生效日期：2026-11-24
- 适用版本：MoreMoney Android 1.0.0 及后续 v1 版本
- 适用平台：Android 8.0（API 26）及以上

## 中文正文

MoreMoney（以下简称“本应用”）是一款完全离线的个人支出记账工具。我们高度重视你的隐私，原则如下：

### 1. 我们不收集、不上传任何个人数据

本应用**未申请网络权限**（Android 权限清单中没有 `INTERNET`），因此无法把你的数据发送到任何服务器。账本、分类、流水、预算和设置只保存在你设备上的应用私有目录中。

### 2. 本机保存的数据

- 账本名称、图标、颜色、默认/归档状态；
- 分类与分组；
- 流水金额（整数分）、日期、备注、所属账本/分类；
- 月度预算；
- 应用设置（默认账本、周起始日、上次备份时间等）。

上述数据仅用于在本机展示、统计与导出。

### 3. 文件导出与备份

- CSV 导出、备份导出、CSV 导入、备份恢复都通过 Android 系统文件选择器（SAF）完成；
- 只有你主动选择文件位置并确认后，应用才会写入或读取该文件；
- 本应用不申请存储权限，也不能访问你未主动选择的其他文件；
- 备份文件由你自行保管，本应用不会上传到云端。

### 4. 系统备份

本应用在 Manifest 中设置 `android:allowBackup="false"`，避免账本数据库进入 Android 系统云备份。卸载应用会删除本机数据；请在卸载前自行导出备份。

### 5. 私密账本

Android v1 **不提供**私密账本、密码、生物识别或加密备份。若导入旧版备份，包含私密账本的 `BOOK` 行与 `PRIVATE` 段会被跳过，恢复预览会显示跳过数量；私密数据不会被当作普通账本导入。

### 6. 第三方 SDK、广告与统计

本应用不集成广告、统计、推送、地图或任何第三方分析 SDK，不进行用户画像、追踪或定向推荐。

### 7. 儿童隐私

本应用不是面向儿童设计的产品，也不会有意收集儿童个人信息（事实上不收集任何人的个人信息）。

### 8. 你的权利

由于数据只存在本机，你可以：

- 在应用内直接查看、修改、删除流水与预算；
- 通过 CSV/备份把数据导出到你选择的位置；
- 卸载应用以删除全部本机数据。

### 9. 政策更新

若未来版本引入网络能力或数据收集，我们会在发布前更新本政策并在应用内/商店页面提示。

### 10. 联系方式

- 开发者：MoreMoney
- 联系邮箱：`<请填写发布者邮箱>`
- 隐私政策 URL：`<请填写公开发布的 URL>`

---

## English Summary

MoreMoney is an offline-only personal expense tracker for Android. The app does **not** request the `INTERNET` permission and does not collect, transmit, sell, or share any personal data. Books, categories, transactions, budgets, and settings are stored only in the app's private storage on your device. CSV/backup import and export happen exclusively through the Android Storage Access Framework after you pick a file. System cloud backup is disabled (`allowBackup=false`). There are no ads, analytics, tracking, or third-party SDKs. Private books are not supported in v1; private books and `PRIVATE` sections in legacy backups are skipped and reported. Contact: `<publisher email>`.
