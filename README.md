# Internal CA Toolkit (Windows) — Root CA / Server Cert / Client Trust

## What This Toolkit Does

- Create and manage a Root CA
- Issue server certificates
- Export and install CA certificates
- Bootstrap client trust
- Verify trusted root certificates

> 適用情境：內部 IIS / 內網系統，使用 HTTPS，但沒有對外公開 CA 或公司內沒有 AD/企業 PKI。

## What This Toolkit Is Not

- A full PKI solution (no CRL, OCSP, or policy enforcement)
- Tied to any specific organization or domain

## Overview

1. **Server 建立 Root CA**（產生 CA 私鑰 + Root 憑證）
2. **Server 使用 Root CA 簽發伺服器憑證**（產生 server 私鑰 + server 憑證，含 SAN）
3. **Server 匯出 Root CA 公鑰憑證**（提供給 Client 安裝信任）
4. **Client 安裝 Root CA 到 Trusted Root**（讓瀏覽器/系統信任內部 HTTPS）
5. （Optional）Client 寫入 hosts（沒有內部 DNS 時）

## Folder structure

```text
project-root/
├── Client/
|   ├── Add-HostsEntry.ps1
|   └── Install-CARootCertificate.ps1
├── Server/
|   ├── Export-CARootCertificate.ps1
|   ├── New-CARootCertificate.ps1
|   └── New-CAServerCertificate.ps1
├── Test/
|   └── Get-TrustedRootCertificates.ps1
├── README.md
└── .gitignore
```

## Requirements

- Windows 10/11 (Client)
- Windows Server (CA / IIS)
- PowerShell 5.1+（Windows 內建即可）
- 權限需求：
  - Server 端建立/匯出憑證：通常需要系統管理員權限
  - Client 安裝 Trusted Root：需要系統管理員權限

## Safety notes (Important)

⚠️ **Root CA 私鑰是最高機密**  

- 不要把 Root CA 私鑰或包含私鑰的檔案（例如 `.pfx`）傳到任何不可信位置
- 不要 commit 到 Git（建議用 `.gitignore` 忽略）

⚠️ 這些腳本內容可能會依本機情況變更：

- Windows 憑證存放區（Cert Store）
- hosts 檔案
- IIS 憑證綁定（如果有）

## Quick start (Recommended path)

### On the CA / Server machine (建立 CA + 簽伺服器憑證)

1. 建立 Root CA
2. 簽發伺服器憑證 (e.g. devops.contoso.com)
3. 匯出 Root CA 公鑰憑證（提供給 Client 安裝）

> 產出檔案（示意）：out\ca-root.cer：Root CA 公鑰憑證（可分發）

### On each Client (安裝信任 + 測試)

1. 安裝 Root CA 到 Trusted Root
2. （Optional）沒有 DNS 時加 hosts
3. 測試
   - 用瀏覽器開：<https://devops.contoso.com>
   - 應該不再出現憑證不受信任警告

### Script reference (What each script does)

#### Server

- `New-CARootCertificate.ps1`：建立本機 Root CA（會產生私鑰+自簽 Root 憑證）

- `New-CAServerCertificate.ps1`：用 Root CA 簽出伺服器憑證（IIS/HTTPS 用）

- `Export-CARootCertificate.ps1`：匯出 Root CA 公鑰憑證（給 Client 安裝信任）

#### Client

- `Install-CARootCertificate.ps1`：在 Client 安裝 Root CA 到 Trusted Root（使瀏覽器信任內網 HTTPS）

- `Add-HostsEntry.ps1`：新增 hosts 對應（沒有內部 DNS 時用）

## Troubleshooting

### 執行權限不足

1. 用系統管理員開 PowerShell
2. 或用右鍵「以系統管理員身分執行」
3. 也可自行嘗試建立捷徑 (*.lnk)：
    - 目標欄位：`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File <腳本路徑>`

      或

    - 捷徑右鍵 -> 捷徑分頁 -> 進階 -> 勾選`以系統管理員身分執行` -> 確定

### 仍出現憑證不受信任

1. 確認 Root CA 有裝到：`Trusted Root Certification Authorities (受信任的根憑證授權單位)`
2. 重新開啟瀏覽器（或重新開機）
3. 檢查簽發的 server cert 是否確實由該 Root CA 簽發（憑證鏈是否中斷），檢視憑證鏈上各憑證之以下項目相符/對應：
   - 簽章(雜湊)演算法
   - 簽發者
   - 主體/主體別名 (CN/DNS)
   - 憑證指紋

### 瀏覽器找不到站台/連線逾時

1. DNS/hosts 是否指向正確 server IP
2. Server 防火牆是否允許 port 443 (https)
3. IIS binding 設定是否正確（SNI勾選/憑證選擇正確）

## PowerShell Script Naming Convention

- 檔名一律：`Verb-Noun.ps1`
- Verb 用 PowerShell 官方常見：`Get/New/Set/Add/Remove/Import/Export/Install/Uninstall/Test`
- Noun 用 `單數` + `PascalCase（e.g. CARootCertificate / HostsEntry / TrustedRoot）`
- 不要在 Verb 前放前綴（e.g. 避免 CA-New-*），領域放到 Noun 裡：New-CARootCertificate
- `One script = one responsibility`：一個腳本專心做好一件事
