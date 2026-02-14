#!/bin/bash

# --- 函數定義 ---
# 顯示使用說明
show_help() {
    echo "用法: $0 [選項]"
    echo "選項:"
    echo "  -c, --create     建立符號連結 (預設行為)"
    echo "  -r, --remove     移除符號連結並還原原始檔案"
    echo "  -h, --help       顯示此幫助訊息"
    echo "  -y, --yes        跳過確認步驟，直接執行"
    echo "  -v, --verbose    顯示詳細輸出"
    echo "  -q, --quiet      只顯示錯誤訊息"
    echo ""
    echo "範例:"
    echo "  $0 -c -y      # 建立符號連結，跳過確認"
    echo "  $0 -r         # 移除符號連結並還原原始檔案"
    exit 0
}

# 初始化變數
ACTION="create"  # 預設為建立模式
CONFIRM_BEFORE_MOVE=true
VERBOSE=true

# 解析命令列參數
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--create)
            ACTION="create"
            shift
            ;;
        -r|--remove)
            ACTION="remove"
            shift
            ;;
        -y|--yes)
            CONFIRM_BEFORE_MOVE=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            VERBOSE=false
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "錯誤: 未知的選項 $1"
            show_help
            exit 1
            ;;
    esac
done

# --- 變數設定 ---
# 1. 你的外接硬碟路徑。
# 請將這裡替換成你的實際路徑，例如 /Volumes/MyExternalHDD
EXTERNAL_DRIVE_PATH="/Volumes/KINGSTON/symlink-data"

# 2. 需要轉移的資料夾映射
# 格式: "原始路徑:外接硬碟相對路徑"
# 注意: 外接硬碟相對路徑是相對於 EXTERNAL_DRIVE_PATH 的路徑
FOLDER_MAPPINGS=(
    # 範例: 
    # "$HOME/Documents/大型專案資料夾:Documents/Projects"
    # "$HOME/Library/Caches/SomeAppCache:Library/Caches/AppCache"
    # "$HOME/.vscode/extensions:Apps/vscode/extensions"
    # "$HOME/Library/Application Support/Google/Chrome/Default:Google/Chrome/Default"

    # vscode
    "$HOME/.vscode/extensions:vscode/extensions"
    "$HOME/Library/Application Support/Code:vscode/Code-Data"
    # vscode-insider
    "$HOME/.vscode-insiders/extensions:vscode-insider/extensions"
    "$HOME/Library/Application Support/Code - Insiders:vscode-insider/Code-Insiders-Data"
    # # windsurf
    # "$HOME/.windsurf/extensions:windsurf/extensions"
    # "$HOME/Library/Application Support/Windsurf:windsurf/Windsurf-Data"
    # "$HOME/.codeium/windsurf/ws-browser:windsurf/ws-browser"
    # "$HOME/.codeium/windsurf/cascade:windsurf/cascade" # 聊天記錄
    # # cursor
    # "$HOME/.cursor/extensions:cursor/extensions"
    # "$HOME/Library/Application Support/Cursor:cursor/Cursor-Data"

    # antigravity
    "$HOME/.gemini/antigravity:antigravity/Antigravity-Data"
    "$HOME/.antigravity/extensions:antigravity/extensions"

    # edge
    "$HOME/Library/Application Support/Microsoft Edge:edge/Edge-User-Data"
    "$HOME/Library/Caches/Microsoft Edge:edge/Edge-Caches" # 只是快取，可清空
    # chrome
    "$HOME/Library/Application Support/Google/Chrome:chrome/Chrome-User-Data"
    "$HOME/Library/Caches/Google/Chrome:chrome/Chrome-Caches" # 只是快取，可清空

    # go
    # 注意：~/go這個資料夾我是直接修改.zshrc的$GOPATH
    "$HOME/Library/Caches/go-build:go-symlink/go-build" # 只是快取，可清空

    # Android
    "$HOME/Library/Android:Android"
    "$HOME/.gradle:Android/gradle" # 只是快取，可清空

    # Xcode
    # "$HOME/Library/Developer/CoreSimulator:Xcode/CoreSimulator" # 模擬器，這個用了模擬器會讀不到，GG
    # "$HOME/Library/Caches/com.apple.dt.Xcode:Xcode/Caches" # 只是快取，可清空
    # "$HOME/Library/Developer/Xcode:Xcode/Xcode-Data" # Xcode相關資料
    # "$HOME/Library/Caches/Xcode:Xcode/Caches2" # 只是快取，可清空
    # 只是快取，可直接清空
    # "/Library/Developer/CoreSimulator/Caches/*"

    # Steam
    "$HOME/Library/Application Support/Steam:Steam"

    # Notion
    "$HOME/Library/Application Support/Notion:Notion"
)

# 3. 是否在移動前進行確認 (true/false)
CONFIRM_BEFORE_MOVE=true

# 4. 是否顯示詳細輸出 (true/false)
VERBOSE=true
# --- 變數設定結束 ---

# 輸出函數
log() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

error() {
    local RED
    RED=$(tput setaf 1)
    local RESET
    RESET=$(tput sgr0)
    echo "${RED}[錯誤] $1${RESET}"
}

success() {
    local GREEN
    GREEN=$(tput setaf 2)
    local RESET
    RESET=$(tput sgr0)
    echo "${GREEN}[成功] $1${RESET}"
}

warning() {
    local YELLOW
    YELLOW=$(tput setaf 3)
    local RESET
    RESET=$(tput sgr0)
    echo "${YELLOW}[警告] $1${RESET}"
}

# 檢查外接硬碟是否存在
if [ ! -d "$EXTERNAL_DRIVE_PATH" ]; then
    error "找不到外接硬碟路徑: $EXTERNAL_DRIVE_PATH"
    exit 1
fi

# 主程式開始
if [ "$ACTION" = "create" ]; then
    echo "=== 開始處理符號連結建立 ==="
else
    echo "=== 開始處理符號連結還原 ==="
fi

# 檢查是否有設定任何資料夾映射
if [ ${#FOLDER_MAPPINGS[@]} -eq 0 ]; then
    warning "未設定任何要轉移的資料夾。請在 FOLDER_MAPPINGS 中新增您的資料夾映射。"
    exit 0
fi

# 處理每個資料夾映射
for mapping in "${FOLDER_MAPPINGS[@]}"; do
    # 分割原始路徑和目標相對路徑
    IFS=':' read -r source_path target_relative_path <<< "$mapping"
    
    # 檢查原始路徑是否為空
    if [ -z "$source_path" ] || [ -z "$target_relative_path" ]; then
        warning "無效的映射格式: $mapping (應為 原始路徑:外接硬碟相對路徑)"
        continue
    fi
    
    # 處理 ~ 擴展
    source_path="${source_path/#\~/$HOME}"
    
    # 構建完整目標路徑
    target_path="${EXTERNAL_DRIVE_PATH}/${target_relative_path}"
    
    echo -e "\n=== 處理: $source_path => $target_path ==="
    
    # 檢查原始路徑是否存在
    if [ ! -e "$source_path" ]; then
        warning "原始路徑不存在: $source_path"
        continue
    fi
    
    if [ "$ACTION" = "create" ]; then
        # 建立符號連結的邏輯
        
        # 如果目標路徑已經存在，檢查是否為符號連結
        if [ -L "$source_path" ]; then
            current_link=$(readlink "$source_path")
            if [ "$current_link" = "$target_path" ]; then
                success "符號連結已正確設定: $source_path -> $target_path"
            else
                warning "$source_path 已存在，但指向不同的位置: $current_link"
            fi
            continue
        fi
        
        # 確認是否要移動資料
        move_confirmed=true
        if [ "$CONFIRM_BEFORE_MOVE" = true ]; then
            read -p "是否要移動 $source_path 到 $target_path 並建立符號連結? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                move_confirmed=false
                warning "已跳過: $source_path"
            fi
        fi
        
        if [ "$move_confirmed" = true ]; then
            # 確保目標目錄存在
            mkdir -p "$(dirname "$target_path")" || {
                error "無法建立目標目錄: $(dirname "$target_path")"
                continue
            }
            
            # 移動資料
            log "移動資料: $source_path -> $target_path"
            mv "$source_path" "$target_path" || {
                error "移動資料時發生錯誤"
                continue
            }
            
            # 建立符號連結
            log "建立符號連結: $source_path -> $target_path"
            ln -s "$target_path" "$source_path" || {
                error "建立符號連結時發生錯誤"
                continue
            }
            
            success "已完成: $source_path -> $target_path"
        fi
    else
        # 還原符號連結的邏輯
        
        # 檢查是否為符號連結
        if [ -L "$source_path" ]; then
            current_link=$(readlink "$source_path")
            
            # 確認是否要還原
            restore_confirmed=true
            if [ "$CONFIRM_BEFORE_MOVE" = true ]; then
                read -p "是否要還原 $source_path 的符號連結? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    restore_confirmed=false
                    warning "已跳過: $source_path"
                fi
            fi
            
            if [ "$restore_confirmed" = true ]; then
                # 檢查目標路徑是否存在
                if [ ! -e "$target_path" ]; then
                    warning "目標路徑 $target_path 不存在，無法還原"
                    continue
                fi
                
                # 刪除符號連結
                log "刪除符號連結: $source_path -> $current_link"
                rm "$source_path" || {
                    error "刪除符號連結時發生錯誤"
                    continue
                }
                
                # 移動資料回原始位置
                log "移動資料回原始位置: $target_path -> $source_path"
                mv "$target_path" "$source_path" || {
                    error "移動資料回原始位置時發生錯誤"
                    continue
                }
                
                success "已還原: $source_path"
            fi
        else
            if [ -e "$source_path" ]; then
                log "$source_path 不是符號連結，無需還原"
            else
                warning "$source_path 不存在，無法還原"
            fi
        fi
    fi
done

echo "---------------------------------"
if [ "$ACTION" = "create" ]; then
    echo "所有符號連結建立完成。請檢查您的應用程式是否正常運作。"
else
    echo "所有符號連結還原完成。請檢查您的應用程式是否正常運作。"
fi
echo "---------------------------------"

# 顯示使用說明
echo -e "\n=== 使用說明 ==="
echo "1. 在 FOLDER_MAPPINGS 陣列中新增您的資料夾映射"
echo "   格式: \"原始路徑:外接硬碟相對路徑\""
echo "2. 執行腳本時使用以下選項:"
echo "   -c, --create   建立符號連結 (預設)"
echo "   -r, --remove   移除符號連結並還原原始檔案"
echo "   -y, --yes      跳過確認步驟，直接執行"
echo "   -v, --verbose  顯示詳細輸出"
echo "   -q, --quiet    只顯示錯誤訊息"

echo -e "\n=== 範例 ==="
echo "# 建立符號連結 (互動式)"
echo "$0"
echo "# 建立符號連結 (非互動式)"
echo "$0 -c -y"
echo "# 還原符號連結"
echo "$0 -r"