# Cloak Browser 自动签到助手

> **English → [README.en.md](README.en.md)**

基于 [Cloak Browser](https://cloakbrowser.dev) 绕过 Cloudflare 验证，实现 PT 站每日自动签到。

**内置站点模板：** ourbits.club · audiences.me · 以及任意 NexusPHP 站点

---

## 一键启动

### Linux / macOS

```bash
chmod +x run.sh
./run.sh
```

### Windows

双击运行 `run.bat`

**首次运行时，脚本会自动完成以下步骤：**

1. 检测 Python 3.8+（未安装时给出安装提示）
2. 自动安装 `cloakbrowser` 依赖
3. 打开**配置向导**，引导你添加站点和填写账号密码
4. 执行签到

之后每次运行直接跳过配置，自动签到。

---

## 命令说明

| 命令 | 说明 |
|------|------|
| `./run.sh` | 首次自动配置，之后直接签到所有站点 |
| `./run.sh --setup` | 打开配置向导（添加/编辑/删除站点） |
| `./run.sh --login` | 清除 cookies 并强制重新登录 |
| `./run.sh ourbits` | 只对 ourbits 签到 |

Windows 将 `./run.sh` 替换为 `run.bat`。

---

## 配置向导功能

运行 `./run.sh --setup` 进入交互式配置向导：

```
当前已配置站点：
  1. ourbits — https://ourbits.club  [启用]
  2. audiences — https://audiences.me  [启用]

操作菜单：
  1) 添加站点
  2) 编辑站点（修改账号/密码/启用状态）
  3) 删除站点
  4) 清除 cookies（强制重新登录）
  5) 保存并退出
  0) 不保存退出
```

支持从内置模板快速添加，或手动填写任意 NexusPHP 站点的 URL 和配置。

---

## 环境要求

- Python 3.8+
- 各 PT 站的有效账号

## 注意事项

- `config.json` 保存站点配置和账号密码，已加入 `.gitignore`，不会提交到 Git。
- 浏览器配置文件（`profile_*/`）和 cookies（`cookies_*.json`）同样已排除。
- 首次登录带图片验证码的站点时，脚本会提示手动输入验证码。
- 登录成功后 cookies 会持久化，会话过期前无需重新登录。
