# Pen

macOS 螢幕標註工具，靈感來自 Windows PowerToys 的 Screen Ruler / Annotation 功能。

![macOS](https://img.shields.io/badge/macOS-26.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 功能特色

- **全局快捷鍵** - 使用 `⌘+2` 隨時啟動/關閉標註模式（無需輔助使用權限）
- **自由繪圖** - 支援紅、綠、藍、黃四種顏色
- **形狀繪製** - 按住修飾鍵拖動即可繪製矩形、圓形、箭頭
- **文字標註** - 在任意位置添加文字
- **橡皮擦** - 擦除任意標註元素
- **截圖功能** - 將標註內容截圖保存到桌面
- **多螢幕支援** - 獨立處理每個螢幕的標註
- **無限撤銷/重做** - 隨時修改你的標註

## 安裝

### 方法一：下載 DMG（推薦）

從 [Releases](../../releases) 頁面下載最新的 `Pen.dmg`，打開後將 `pen.app` 拖到 Applications 資料夾。

### 方法二：從源碼編譯

```bash
git clone https://github.com/你的用戶名/pen.git
cd pen
xcodebuild -project pen.xcodeproj -scheme pen -configuration Release build
```

或在 Xcode 中打開 `pen.xcodeproj`，按 `⌘+R` 運行。

## 快捷鍵

### 基本操作

| 快捷鍵 | 功能 |
|--------|------|
| `⌘+2` | 啟動/關閉標註模式 |
| `Esc` | 退出標註模式 |
| `⌘+6` | 截圖（保存到桌面） |

### 工具切換

| 快捷鍵 | 功能 |
|--------|------|
| `R` | 紅色筆 |
| `G` | 綠色筆 |
| `B` | 藍色筆 |
| `Y` | 黃色筆 |
| `E` | 橡皮擦 |
| `⌘+T` | 文字工具 |
| `⌘++` | 增加筆刷大小 |
| `⌘+-` | 減少筆刷大小 |

### 形狀繪製（拖動時按住）

| 修飾鍵 | 形狀 |
|--------|------|
| `⌘` | 矩形 |
| `⌘+Shift` | 箭頭 |
| `Option` | 圓形 |

### 編輯

| 快捷鍵 | 功能 |
|--------|------|
| `⌘+Z` | 撤銷 |
| `⌘+Shift+Z` | 重做 |

## 技術細節

- 使用 **Carbon HotKey API** 實現全局快捷鍵，無需輔助使用權限
- 使用 **SwiftUI Canvas** 進行高效能繪圖
- 支援 **CGDirectDisplayID** 實現多螢幕獨立標註

## 系統要求

- macOS 26.0 或更高版本

## 授權

MIT License
