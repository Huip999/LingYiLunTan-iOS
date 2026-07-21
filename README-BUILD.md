# 凌意论坛 iOS 版 —— 编译打包说明

> 这套工程是从 Android APK (`top.lingyiluntan.app` v1.7.6) **等价重写**的 iOS 应用，
> 功能一致：WKWebView 加载 `https://lingyiluntan.top/`，带 Cookie 持久化（记住登录）、下拉刷新、JS 弹窗、外链跳 Safari。
>
> ⚠️ **APK 无法直接转 IPA**，这是重写的等价工程。**IPA 只能在 macOS 上编译**，Windows 不行。

---

## 你需要什么

| 条件 | 必须？ | 说明 |
|------|--------|------|
| 一台 Mac | ✅ 必须 | 黑苹果 / 云 Mac 也行，下面有云 Mac 方案 |
| Xcode 15+ | ✅ 必须 | App Store 免费下载 |
| Apple ID | ✅ 必须 | 免费的就行，用来签名安装到真机 |
| Apple 开发者账号 $99/年 | ❌ 可选 | 免费用 sideload，签名 7 天有效；付费 1 年有效 |

---

## 方式一：本地有 Mac（最简单）

```bash
# 1. 把整个 LingYiLunTan-iOS 文件夹拷到 Mac 上

# 2. 打开终端，cd 进去
cd /path/to/LingYiLunTan-iOS

# 3.（可选）如果 .xcodeproj 打不开，用 XcodeGen 重新生成
brew install xcodegen
xcodegen generate

# 4. 一键打包
bash build-ipa.sh

# 产出在 build/LingYiLunTan.ipa
```

也可以用 Xcode GUI：
1. 双击 `LingYiLunTan.xcodeproj` 打开
2. 菜单 Product → Archive
3. Archive 完成后 → Distribute App → Custom → Copy App（得到 .ipa）

---

## 方式二：没有 Mac，用云 Mac（免费额度够用）

### GitHub Actions（免费，推荐）

1. 把本工程推到 GitHub 仓库
2. 在仓库里创建 `.github/workflows/build.yml`（我可以帮你写）
3. 每次 push 自动在 GitHub 的 macOS runner 上编译出 IPA，下载即可

### 其他云 Mac

- **MacinCloud**（按小时租，约 $1/小时）
- **Colab** + macOS Docker（不稳定，不推荐）

---

## 签名 & 安装到 iPhone

### 免费方案（Apple ID，7 天有效）

1. 电脑装 [Sideloadly](https://sideloadly.io)（Win/Mac 都行）
2. iPhone 用线连电脑
3. Sideloadly 里选 `build/LingYiLunTan.ipa`，填你的 Apple ID
4. 点 Start，等签名+安装完成
5. iPhone 上 设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID 证书
6. 桌面出现「凌意论坛」图标，打开即用

> 7 天后需要重新签名，再跑一次 Sideloadly 即可（App 数据不丢）。

### 付费方案（开发者账号，1 年有效）

把 `build-ipa.sh` 里的 `DEVELOPMENT_TEAM` 改成你的 Team ID，
去掉 `CODE_SIGNING_ALLOWED=NO`，换成正式签名参数即可。

---

## 工程结构

```
LingYiLunTan-iOS/
├── LingYiLunTan.xcodeproj/     # Xcode 工程文件
│   └── project.pbxproj
├── LingYiLunTan/                # 源码
│   ├── AppDelegate.swift        # 应用入口
│   ├── SceneDelegate.swift      # 场景管理
│   ├── WebViewController.swift  # 核心：WKWebView 控制器
│   ├── Info.plist               # 配置（ATS、横竖屏等）
│   └── Assets.xcassets/         # 图标资源（需自己放 1024x1024 图标）
├── project.yml                  # XcodeGen 备份配置
├── build-ipa.sh                 # 一键打包脚本
└── README-BUILD.md              # 本说明
```

---

## 改论坛地址

如果论坛换了域名，改 `WebViewController.swift` 第 14 行：

```swift
private let homeURL = URL(string: "https://lingyiluntan.top/")!
```

---

## 常见问题

**Q: 编译报错 "No such module" / 找不到文件？**
A: 用 `xcodegen generate` 重新生成工程再试。

**Q: Sideloadly 报错 "An App ID with identifier is not available"？**
A: 免费账号对 Bundle ID 有限制，改 `project.pbxproj` 里的 `PRODUCT_BUNDLE_IDENTIFIER` 成你自己的（如 `com.你的名字.forum`）。

**Q: 打开后白屏？**
A: 论坛服务器本身挂了（和 APK 无关），等 `lingyiluntan.top` 恢复即可。
