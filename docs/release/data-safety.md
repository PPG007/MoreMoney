# Google Play Data Safety 表单建议答案

依据：Android v1 无 `INTERNET` 权限、无第三方 SDK、系统云备份关闭。以下为填写建议，提交前请再核对实际发布包。

## Data collection and security

| 问题 | 建议答案 |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A（不收集、不传输） |
| Do you provide a way for users to request that their data is deleted? | Yes（应用内删除/卸载即删除本机数据；用户可自行导出备份） |

## Data types

- Location：No
- Personal info：No
- Financial info：No（账目仅保存在本机，不上传）
- Health and fitness：No
- Messages：No
- Photos and videos：No
- Audio：No
- Files and docs：No（仅通过 SAF 读写用户主动选择的本地文件，不上传）
- Calendar：No
- Contacts：No
- App activity：No
- Web browsing：No
- App info and performance：No
- Device or other IDs：No

## Data usage and handling

| 问题 | 建议答案 |
|---|---|
| Is data collected for advertising or marketing? | No |
| Is data shared with third parties? | No |
| Is data used for personalization? | No |
| Is data used for app functionality? | No（数据不离开设备） |
| Is data ephemeral? | N/A |

## Permissions

- 网络：无 `INTERNET` / `ACCESS_NETWORK_STATE`
- 存储：无 `READ/WRITE_EXTERNAL_STORAGE`；使用 SAF 的逐文件授权
- 其他：仅 AndroidX 自动生成的 `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`（应用内部使用）

## 证据

```bash
$ANDROID_HOME/build-tools/36.0.0/aapt2 dump permissions \
  app/build/outputs/apk/release/app-release-unsigned.apk
```

输出仅包含 `com.github.ppg007.moremoney.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`，无 `android.permission.INTERNET`。
