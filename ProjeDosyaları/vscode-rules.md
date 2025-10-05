# VS Code Workspace Kuralları

Bu dosya, diskhastanesi.com projesinin VS Code workspace yapılandırmalarını içerir.

## 1. Workspace Ayarları (settings.json)

### Chat & MCP Ayarları
```jsonc
{
  "chat.agent.maxRequests": 50,
  "chat.mcp.discovery": {
    "enabled": true
  },
  "chat.mcp.access": "all"
}
```

### Otomatik Onay Kuralları
Aşağıdaki dosyalar manuel onay gerektirir:
- Environment dosyaları: `**/.env`, `**/.env.*`
- Governance dosyaları: `PROJECT_RULES.md`, `AGENTS.md`
- Runbook'lar: `docs/runbooks/**`
- Workflow'lar: `.github/workflows/**`
- MCP yapılandırmaları: `mcp/**`

Diğer tüm dosyalar otomatik onaylanır.

### Prompt Önerileri
- `mcp-preflight`: Her zaman önerilir
- `mcp-drift-review`: `docs/updates` dizininde çalışırken
- `mcp-onboarding`: Her zaman önerilir
- `mcp-release-check`: `docs/updates` veya `docs/delivery` dizinlerinde
- `docs-divio-structure`: Divio dokümantasyon dizinlerinde

### Edge DevTools Ayarları
```jsonc
{
  "vscode-edge-devtools.browserFlavor": "Default",
  "vscode-edge-devtools.defaultEntrypoint": "http://localhost:3000",
  "vscode-edge-devtools.defaultUrl": "http://localhost:3000",
  "vscode-edge-devtools.browserArgs": ["--remote-debugging-port=9222"],
  "vscode-edge-devtools.headless": false,
  "vscode-edge-devtools.hostname": "localhost"
}
```

### MCP Discovery Ayarları
Desteklenen platformlar:
- Claude Desktop
- Windsurf
- Cursor (Global & Workspace)

## 2. Önerilen Extension'lar (extensions.json)

```jsonc
{
  "recommendations": [
    "ms-edgedevtools.vscode-edge-devtools"
  ]
}
```

## 3. Task Yapılandırması (tasks.json)

### Test Task'ı
```jsonc
{
  "label": "Run Tests",
  "type": "shell",
  "command": "npm",
  "args": ["run", "test"],
  "isBackground": false,
  "problemMatcher": ["$tsc", "$eslint-stylish"]
}
```

**Not:** tasks.json'da aynı task 4 kez tekrarlanmış (temizleme gerekebilir).

## 4. Debug Yapılandırması (launch.json)

### Ana Yapılandırmalar

1. **Launch Diskhastanesi Local**
   - Type: MS Edge
   - URL: http://localhost:3000
   - Web root: ${workspaceFolder}/web
   - Remote debugging port: 9222

2. **Launch Diskhastanesi Local (Headless)**
   - Headless modda çalışır
   - Diğer ayarlar yukarıdaki ile aynı

3. **Open Edge DevTools**
   - Type: vscode-edge-devtools.debug
   - Attach modunda
   - Presentation: hidden

4. **Attach to Edge**
   - Çalışan Edge instance'ına bağlanır
   - Port: 9222

## 5. Chat Tool Sets (chat.toolsets.jsonc)

### repo-docs Tool Set
```jsonc
{
  "repo-docs": {
    "description": "Read-only access helpers for the repo-docs MCP server",
    "icon": "book",
    "tools": [
      "read_file_chunk",
      "search_files",
      "stat_file"
    ]
  }
}
```

Bu tool set, MCP repo-docs server'ı için sadece okuma erişimi sağlar.

## Microsoft'a Taşıma Notları

### Visual Studio Karşılıkları
1. **settings.json** → `.vs/` klasöründe `settings.json` veya solution ayarları
2. **tasks.json** → MSBuild targets veya custom build tasks
3. **launch.json** → `launchSettings.json` (Properties klasöründe)
4. **extensions.json** → Visual Studio extension recommendations (`.vsconfig`)

### Değiştirilmesi Gerekenler
- Edge DevTools → Visual Studio built-in debugger
- MCP discovery → Microsoft Copilot entegrasyonu
- Chat ayarları → Visual Studio AI assistant ayarları
- npm tasks → dotnet CLI commands veya MSBuild targets

### Korunması Gerekenler
- Otomatik onay kuralları mantığı
- Environment dosya güvenlik kuralları
- Debug port yapılandırmaları (9222 → uygun .NET debug port'u)
