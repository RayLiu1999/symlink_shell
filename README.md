## symlink_shell.sh

這個腳本用來將本機的資料夾搬到外接硬碟（或其他指定目錄），再在原位置建立符號連結（symlink），方便將大量資料或快取移到外接磁碟節省本機空間；也支援還原（移回原處並移除 symlink）。

### 功能摘要
- 建立符號連結：將本機指定資料夾移動到 `EXTERNAL_DRIVE_PATH` 下指定位置，再在原路徑建立符號連結。
- 還原符號連結：若原位置為 symlink，會把外接硬碟上的資料移回原處並移除 symlink。
- 互動式確認或跳過確認（`-y`）。
- 可切換詳細/安靜輸出。

### 檔案位置
腳本檔案：`/Volumes/KINGSTON/symlink-data/symlink_shell.sh`

### 快速上手
1. 編輯腳本內的變數：
   - `EXTERNAL_DRIVE_PATH`：設定外接硬碟或欲放置資料的根目錄（範例預設為 `/Volumes/KINGSTON/symlink-data`）。
   - `FOLDER_MAPPINGS`：在腳本中以陣列形式指定要轉移的資料夾對應關係，格式為 `"原始路徑:外接硬碟相對路徑"`。

2. 範例映射（腳本內已範例）：
   - `"$HOME/.vscode/extensions:vscode/extensions"` 會把 `$HOME/.vscode/extensions` 移到 `/Volumes/KINGSTON/symlink-data/vscode/extensions`，並在原處建立 symlink。

3. 執行腳本（互動式，建立 symlink）：
```bash
cd /Volumes/KINGSTON/symlink-data
./symlink_shell.sh
```

4. 執行腳本（非互動式，跳過確認）：
```bash
./symlink_shell.sh -c -y
```

5. 還原所有 symlink（互動式確認每一個）：
```bash
./symlink_shell.sh -r
```

### 可用選項
- `-c, --create`：建立符號連結（預設動作）。
- `-r, --remove`：還原符號連結，把資料移回原位並移除 symlink。
- `-y, --yes`：跳過互動確認（自動同意移動/還原）。
- `-v, --verbose`：顯示詳細輸出（預設）。
- `-q, --quiet`：只顯示錯誤訊息。
- `-h, --help`：顯示說明。

### `FOLDER_MAPPINGS` 格式說明
- 每個項目為字串，使用冒號 `:` 分隔原始絕對路徑與在外接磁碟上的相對路徑（相對於 `EXTERNAL_DRIVE_PATH`）。
- 支援 `$HOME` 與 `~` 展開（腳本會處理 `~`）。
- 範例：
  - `"$HOME/Library/Application Support/Google/Chrome:chrome/Chrome-User-Data"`

### 安全與注意事項
- 在移動資料前請先備份重要資料。
- 確認 `EXTERNAL_DRIVE_PATH` 指向正確且有足夠可用空間。
- 如果原路徑已存在但不是 symlink，腳本會在建立時提示或跳過，請小心不要覆蓋重要檔案。
- 還原流程假設外接磁碟上的目標路徑尚存在且為要還原的資料，若外接磁碟內容遺失，還原會失敗。

### 常見問題（Troubleshooting）
- 無法建立目標目錄：確保對 `EXTERNAL_DRIVE_PATH` 有寫入權限，且磁碟已掛載。
- `mv` 時失敗（權限或檔案被使用）：請關閉使用相關資料的應用程式，或用 `sudo`（慎用）。
- 已建立 symlink，但應用程式無法運作：確認外接磁碟路徑與權限，並檢查 symlink 指向是否正確（`readlink <path>`）。

### 小技巧
- 可先逐一測試單個映射，確保不會影響工作流程，再批次執行整份 `FOLDER_MAPPINGS`。
- 若要把 `~/go` 改到外接硬碟，可只修改你的 shell 設定（如 `.zshrc`）中的 `GOPATH`，或用腳本把 `~/Library/Caches/go-build` 等快取移動。

### 範例工作流程
1. 編輯 `symlink_shell.sh`，確認 `EXTERNAL_DRIVE_PATH` 與 `FOLDER_MAPPINGS`。
2. 執行 `./symlink_shell.sh -c`（互動）或 `./symlink_shell.sh -c -y`（一次完成）。
3. 檢查每個來源路徑是否已變成 symlink：`ls -la <path>`。

### 授權
此 README 與腳本範例不含授權條款。若要分享或改作，請自行補上 license（例如 MIT）。

---
README 依 `symlink_shell.sh` 腳本行為與參數撰寫；如需我直接把 README 新增到專案中或調整內容（語言/長度/更技術化），請告訴我要修改的方向.
