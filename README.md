# Claude Cage Lite

轻量级 Claude Code 沙箱，专为 **Windows + Docker Desktop** 设计。

**核心特性：Claude 登录状态与主机完全隔离。**

- 只挂载当前项目目录
- Claude 的配置、登录凭证、历史记录全部存放在 Docker named volume 中
- 主机 `~/.claude`、`%USERPROFILE%\.claude` 等目录**永远不会**被访问
- 支持多 volume，轻松管理多个独立账号 / 工作区

---

## 前置要求

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)（推荐开启 WSL2 backend）
2. 确保 Docker Desktop 已启动

可选：
- Git Bash（如果想用 bash 版启动脚本）
- PowerShell（推荐，原生支持）

---

## 快速开始

### 1. 克隆仓库

```powershell
git clone https://github.com/Shuaidaobeimiaosha/claude-cage-lite.git
cd claude-cage-lite
```

### 2. 使用 PowerShell 启动（推荐）

```powershell
# 进入你的项目目录
cd D:\path\to\your\project

# 首次运行会自动构建镜像
..\claude-cage-lite\bin\claude-cage.ps1
```

为了更方便，可以把脚本加到 PATH，或创建一个别名：

```powershell
# 临时别名
Set-Alias claude-cage "D:\path\to\claude-cage-lite\bin\claude-cage.ps1"

# 之后直接用
claude-cage
claude-cage -Volume personal
```

### 3. 常用命令

```powershell
# 默认 volume（登录状态隔离）
.\bin\claude-cage.ps1

# 使用独立 volume（适合多账号）
.\bin\claude-cage.ps1 -Volume work
.\bin\claude-cage.ps1 -Volume personal

# 强制重建镜像
.\bin\claude-cage.ps1 -Rebuild

# 进入容器内部 shell（调试用）
.\bin\claude-cage.ps1 -Shell

# 直接传参数给 Claude
.\bin\claude-cage.ps1 "解释一下这个项目的结构"
```

---

## 隔离说明

| 内容                          | 位置                              | 是否与主机共享 |
|-------------------------------|-----------------------------------|----------------|
| 项目代码                      | 当前目录 → `/workspace`           | 是（只读写当前项目） |
| Claude 登录凭证 / 配置 / 历史 | Docker volume → `/home/claude`    | **否（完全隔离）** |
| 主机其他文件 / SSH 密钥       | 不挂载                            | **否**         |
| 主机 `~/.claude` 等目录       | 不挂载                            | **否**         |

每次启动时会自动创建/使用 named volume。不同 `-Volume` 名称对应不同的隔离登录状态。

---

## 代理支持

如果主机设置了代理环境变量（`HTTP_PROXY` / `HTTPS_PROXY` 等），启动脚本会自动透传进容器。

也可以手动设置：

```powershell
$env:HTTP_PROXY  = "http://127.0.0.1:7890"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
.\bin\claude-cage.ps1
```

---

## 多账号管理建议

```powershell
# 工作账号
claude-cage -Volume work

# 个人账号
claude-cage -Volume personal

# 测试账号
claude-cage -Volume test
```

对应 volume 名称：
- `claude-cage-home-work`
- `claude-cage-home-personal`
- `claude-cage-home-test`

可用以下命令查看：

```powershell
docker volume ls | Select-String claude-cage
```

删除某个账号状态：

```powershell
docker volume rm claude-cage-home-personal
```

---

## 目录结构

```
claude-cage-lite/
├── Dockerfile              # 镜像定义
├── bin/
│   ├── claude-cage         # bash 版启动脚本（Git Bash / WSL / Linux）
│   └── claude-cage.ps1     # PowerShell 版（Windows 推荐）
├── .dockerignore
└── README.md
```

---

## 注意事项

1. **第一次运行**会构建镜像，可能需要几分钟（取决于网络）。
2. Claude Code 官方目前对 Windows 原生支持仍在完善中，容器内是 Linux 环境，兼容性通常更好。
3. 项目目录通过 bind mount 共享，Claude 对文件的修改会直接反映到主机。
4. 如需更强网络隔离（例如强制只允许特定域名），可再加自定义 Docker network + proxy 层。

---

## License

MIT
