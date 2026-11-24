# 发布签名

## 1. 原则

- **keystore 与密码不入库、不进聊天记录**。
- 仓库只保留 `keystore.properties.example`；真实 `keystore.properties` 已被 `.gitignore` 忽略。
- 没有签名配置时 `assembleRelease` 仍会成功，产物为 `app-release-unsigned.apk`，用于 CI 的编译/R8 校验。

## 2. 生成 keystore

```bash
keytool -genkeypair -v \
  -keystore ~/moremoney-release.jks \
  -alias moremoney \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass '<STORE_PASSWORD>' \
  -keypass '<KEY_PASSWORD>' \
  -dname "CN=MoreMoney, OU=Mobile, O=MoreMoney, L=Shanghai, ST=Shanghai, C=CN"
```

把 keystore 备份到密码管理器或离线介质；丢失后无法向已安装用户发布同签名升级。

## 3. 本机配置

在仓库根目录创建 `keystore.properties`（不要提交）：

```properties
storeFile=/absolute/path/to/moremoney-release.jks
storePassword=******
keyAlias=moremoney
keyPassword=******
```

`storeFile` 支持绝对路径或相对仓库根目录的路径。

## 4. 构建与校验

```bash
./gradlew :app:assembleRelease
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs \
  app/build/outputs/apk/release/app-release.apk
```

## 5. CI 建议

- CI 用只读的 unsigned 构建做编译、Lint、单测；正式签名只在受控发布流水线执行。
- 若使用 Google Play App Signing，上传密钥（upload key）与商店签名密钥分离；本地 `keystore.properties` 只保存 upload key。
- 不要把 keystore 转为 Base64 写进仓库或日志。

## 6. 本次实测

T26 验证时曾使用临时测试 keystore（`~/.android/mm-release-test.jks`）；2026-11-24 已生成正式 release keystore：

- 路径：`C:\Users\16582\.moremoney-signing\moremoney-release.jks`（PKCS12，RSA 2048，alias `moremoney`）
- 密码与证书指纹：同目录 `credentials.txt`（明文，不入库）
- 证书 SHA-256：`BC:E3:22:5B:85:B9:3C:5C:36:3B:7E:48:77:65:E9:BF:FB:B4:80:23:62:2D:C4:A7:55:31:B5:BE:A7:15:BD:1A`
- 仓库根 `keystore.properties` 已指向该 keystore；`assembleRelease` 产出正式签名包。
