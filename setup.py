"""
Cloak Browser 自动签到助手 — 配置向导
引导用户添加、编辑、删除签到站点及其账号密码。

用法：
  python setup.py           交互式配置向导
  python setup.py --login   清除 cookies 并强制重新登录
"""

import getpass
import json
import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent
CONFIG_FILE = BASE_DIR / "config.json"

# ── 内置站点模板 ──────────────────────────────────────────────────────────────
TEMPLATES = {
    "ourbits": {
        "name": "ourbits",
        "url": "https://ourbits.club",
        "login_path": "/login.php",
        "checkin_path": "/attendance.php",
        "checkin_type": "turnstile",
        "login_captcha": False,
        "login_fields": {"username": "username", "password": "password"},
        "_desc": "OurBits (ourbits.club)",
    },
    "audiences": {
        "name": "audiences",
        "url": "https://audiences.me",
        "login_path": "/login.php",
        "checkin_path": "/attendance.php",
        "checkin_type": "turnstile",
        "login_captcha": True,
        "login_fields": {
            "username": "username",
            "password": "password",
            "captcha_code": "imagestring",
            "captcha_hash": "imagehash",
        },
        "captcha_image_selector": 'img[alt="CAPTCHA"]',
        "_desc": "Audiences (audiences.me)",
    },
}

# ── 颜色 ─────────────────────────────────────────────────────────────────────
def _has_color():
    return sys.stdout.isatty() and os.name != "nt" or (os.name == "nt" and os.environ.get("TERM"))

if _has_color():
    R = "\033[0;31m"; G = "\033[0;32m"; Y = "\033[1;33m"
    C = "\033[0;36m"; B = "\033[1m";    N = "\033[0m"
else:
    R = G = Y = C = B = N = ""

def info(s):  print(f"{C}[*]{N} {s}")
def ok(s):    print(f"{G}[+]{N} {s}")
def warn(s):  print(f"{Y}[!]{N} {s}")
def err(s):   print(f"{R}[-]{N} {s}")
def bold(s):  return f"{B}{s}{N}"


# ── 配置读写 ──────────────────────────────────────────────────────────────────

def load_config() -> dict:
    if not CONFIG_FILE.exists():
        return {"sites": []}
    try:
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        warn("config.json 格式损坏，将重新创建。")
        return {"sites": []}


def save_config(config: dict):
    CONFIG_FILE.write_text(
        json.dumps(config, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    ok(f"配置已保存至 {CONFIG_FILE}")


# ── 输入辅助 ──────────────────────────────────────────────────────────────────

def prompt(msg: str, default: str = "") -> str:
    hint = f" [{default}]" if default else ""
    val = input(f"  {msg}{hint}: ").strip()
    return val if val else default


def prompt_password(site_name: str) -> str:
    while True:
        pwd = getpass.getpass(f"  {C}{site_name}{N} — 密码（输入不显示）: ")
        if pwd:
            return pwd
        warn("密码不能为空，请重新输入。")


def prompt_yn(msg: str, default: bool = False) -> bool:
    hint = "Y/n" if default else "y/N"
    val = input(f"  {msg} ({hint}): ").strip().lower()
    if not val:
        return default
    return val.startswith("y")


def choose(options: list[str], title: str = "请选择") -> int:
    """显示编号菜单，返回 0-based 索引，-1 表示取消。"""
    print(f"\n  {bold(title)}：")
    for i, opt in enumerate(options, 1):
        print(f"    {C}{i}{N}) {opt}")
    print(f"    {C}0{N}) 取消 / 返回")
    while True:
        raw = input("  > ").strip()
        if raw == "0":
            return -1
        if raw.isdigit() and 1 <= int(raw) <= len(options):
            return int(raw) - 1
        warn("请输入有效序号。")


# ── 站点增删改 ────────────────────────────────────────────────────────────────

def add_site(config: dict):
    """引导用户选择内置模板或手动填写自定义 NexusPHP 站点。"""
    template_keys = list(TEMPLATES.keys())
    template_descs = [TEMPLATES[k]["_desc"] for k in template_keys]
    options = template_descs + ["自定义 NexusPHP 站点（手动填写）"]

    idx = choose(options, "选择站点模板")
    if idx == -1:
        return

    if idx < len(template_keys):
        # ── 内置模板 ──────────────────────────────────────────────────────────
        key = template_keys[idx]
        tpl = dict(TEMPLATES[key])
        name = tpl["name"]

        # 检查是否已存在
        existing = next((s for s in config["sites"] if s["name"] == name), None)
        if existing:
            warn(f"站点 '{name}' 已存在。如需修改密码，请使用【编辑】功能。")
            return

        print(f"\n  正在添加：{bold(tpl['_desc'])}")
        user = prompt(f"{C}{name}{N} — 用户名")
        if not user:
            warn("用户名不能为空，已取消。")
            return
        pwd = prompt_password(name)

        entry = {k: v for k, v in tpl.items() if not k.startswith("_")}
        entry["username"] = user
        entry["password"] = pwd
        entry["enabled"] = True
        config["sites"].append(entry)
        ok(f"站点 '{name}' 已添加。")

    else:
        # ── 自定义站点 ─────────────────────────────────────────────────────────
        print(f"\n  {bold('添加自定义站点')}")
        print("  （适用于大多数使用 NexusPHP 的 PT 站）\n")

        name = prompt("站点标识（英文，如 mypthome）").strip()
        if not name or not name.isidentifier():
            warn("站点标识只能包含字母、数字、下划线，已取消。")
            return
        if any(s["name"] == name for s in config["sites"]):
            warn(f"站点 '{name}' 已存在。")
            return

        url = prompt("站点网址（如 https://mypthome.com）").rstrip("/")
        if not url.startswith("http"):
            warn("网址应以 http:// 或 https:// 开头，已取消。")
            return

        login_path   = prompt("登录路径", "/login.php")
        checkin_path = prompt("签到路径", "/attendance.php")

        checkin_types = ["turnstile（Cloudflare Turnstile）", "form（直接提交表单）", "link_click（点击签到链接）"]
        ct_idx = choose(checkin_types, "签到方式")
        if ct_idx == -1:
            return
        checkin_type = ["turnstile", "form", "link_click"][ct_idx]

        has_captcha = prompt_yn("登录页面有图片验证码？", False)

        user = prompt(f"{C}{name}{N} — 用户名")
        if not user:
            warn("用户名不能为空，已取消。")
            return
        pwd = prompt_password(name)

        entry: dict = {
            "name": name,
            "enabled": True,
            "url": url,
            "login_path": login_path,
            "checkin_path": checkin_path,
            "checkin_type": checkin_type,
            "login_captcha": has_captcha,
            "login_fields": {"username": "username", "password": "password"},
            "username": user,
            "password": pwd,
        }
        if has_captcha:
            entry["login_fields"].update({"captcha_code": "imagestring", "captcha_hash": "imagehash"})
            entry["captcha_image_selector"] = 'img[alt="CAPTCHA"]'

        config["sites"].append(entry)
        ok(f"站点 '{name}' 已添加。")


def edit_site(config: dict):
    """修改已有站点的账号密码或启用状态。"""
    if not config["sites"]:
        warn("暂无已配置的站点。")
        return

    names = [f"{s['name']} ({s['url']}) {'[停用]' if not s.get('enabled', True) else ''}"
             for s in config["sites"]]
    idx = choose(names, "选择要编辑的站点")
    if idx == -1:
        return

    site = config["sites"][idx]
    name = site["name"]
    print(f"\n  编辑站点：{bold(name)}")
    print("  （直接回车保留原值）\n")

    new_user = prompt(f"{C}{name}{N} — 新用户名（当前：{site.get('username', '')}）")
    if new_user:
        site["username"] = new_user

    if prompt_yn("重新输入密码？", False):
        site["password"] = prompt_password(name)

    enabled = prompt_yn(f"启用该站点？", site.get("enabled", True))
    site["enabled"] = enabled

    ok(f"站点 '{name}' 已更新。")


def remove_site(config: dict):
    """删除站点。"""
    if not config["sites"]:
        warn("暂无已配置的站点。")
        return

    names = [f"{s['name']} ({s['url']})" for s in config["sites"]]
    idx = choose(names, "选择要删除的站点")
    if idx == -1:
        return

    name = config["sites"][idx]["name"]
    if prompt_yn(f"确认删除站点 '{name}'？", False):
        config["sites"].pop(idx)
        ok(f"站点 '{name}' 已删除。")
    else:
        info("已取消。")


def clear_cookies(config: dict):
    """清除指定站点的 cookies，下次运行时重新登录。"""
    if not config["sites"]:
        warn("暂无已配置的站点。")
        return

    names = [s["name"] for s in config["sites"]]
    names_display = [f"{s['name']} ({s['url']})" for s in config["sites"]]
    names_display.append("全部站点")

    idx = choose(names_display, "选择要清除 cookies 的站点")
    if idx == -1:
        return

    targets = names if idx == len(names) else [names[idx]]
    for name in targets:
        f = BASE_DIR / f"cookies_{name}.json"
        if f.exists():
            f.unlink()
            ok(f"已清除 {name} 的 cookies")
        else:
            info(f"{name} 暂无 cookies")


def show_sites(config: dict):
    sites = config.get("sites", [])
    if not sites:
        print("\n  （尚未配置任何站点）\n")
        return
    print()
    for i, s in enumerate(sites, 1):
        status = f"{G}启用{N}" if s.get("enabled", True) else f"{Y}停用{N}"
        print(f"  {i}. {bold(s['name'])} — {s['url']}  [{status}]")
        print(f"     用户名：{s.get('username', '(未设置)')}")
    print()


# ── 主菜单 ────────────────────────────────────────────────────────────────────

def main():
    # --login 快捷模式
    if "--login" in sys.argv:
        config = load_config()
        clear_cookies(config)
        return

    print()
    print(bold("╔══════════════════════════════════════════╗"))
    print(bold("║  Cloak Browser 自动签到助手 — 配置向导   ║"))
    print(bold("╚══════════════════════════════════════════╝"))

    config = load_config()
    changed = False

    while True:
        print(f"\n  {bold('当前已配置站点：')}")
        show_sites(config)

        print(f"  {bold('操作菜单：')}")
        print(f"    {C}1{N}) 添加站点")
        print(f"    {C}2{N}) 编辑站点（修改账号/密码/启用状态）")
        print(f"    {C}3{N}) 删除站点")
        print(f"    {C}4{N}) 清除 cookies（强制重新登录）")
        print(f"    {C}5{N}) 保存并退出")
        print(f"    {C}0{N}) 不保存退出")
        print()

        choice = input("  > ").strip()

        if choice == "1":
            add_site(config)
            changed = True
        elif choice == "2":
            edit_site(config)
            changed = True
        elif choice == "3":
            remove_site(config)
            changed = True
        elif choice == "4":
            clear_cookies(config)
        elif choice == "5":
            if not config["sites"]:
                warn("尚未添加任何站点，请先添加至少一个站点。")
                continue
            save_config(config)
            break
        elif choice == "0":
            if changed:
                if not prompt_yn("有未保存的更改，确认放弃？", False):
                    continue
            info("已退出（未保存）。")
            break
        else:
            warn("请输入 0-5 之间的数字。")


if __name__ == "__main__":
    main()
