#!/usr/bin/env python3
"""ai-bump：维护者给 PR 打上 request-ai-bump 标签后，用 AI 排查修复构建/测试失败。

移植自 Harmonybrew/ci 的 src/ai_bump.py（AtomGit webhook + buildbot 版），适配
本 tap 的 GitHub Actions 管线，机制对照：
  - 触发：ai-bump.yml 的 pull_request_target + labeled(request-ai-bump)
    （官方是 buildbot 解析 AtomGit webhook）
  - atomgit_api 五个模块的调用全部换成 gh CLI（runner 自带，无 pip 依赖）
  - 官方的双容器编排收敛为单容器：--agent 阶段在 OHOS 容器内跑（同官方），
    推送/评论直接在 runner host 上做，不再需要第二个容器
  - 站内网源码镜像 add-host 与 api.atomgit.com 固定 IP 属 buildbot 专属
    环境，删除
  - git 身份：官方经 AtomGit API 解析；这里直接用 setup-container.sh 已配置
    的 github-actions[bot]

流程（host 模式，workflow 默认入口）：
  1. gh 解析 PR，要求恰好改一个 formula（官方同款约束），且触发标签仍在
     （防并发重复触发：标签开跑即被摘掉，第二次 labeled 事件进来时已无）
  2. 标签交接：摘 request-ai-bump / ci-failed / 上次结果，打 ai-running；
     评论里留 run 链接（官方留 buildbot 流水线编号）
  3. docker exec 进 OHOS 容器跑 --agent 阶段：brew update、把 PR 分支
     rebase 到 origin/main、装 deepseek-harness、跑一次性 dsh 任务、校验
     AI 自声明的 status.json 与报告产物（防幻觉成功：只认 success）
  4. host 上浅克隆（depth 2）PR 源分支，用报告覆盖 formula/Patches，amend
     进原顶端提交后 BOT_PUSH_TOKEN push -f。用 BOT_PUSH_TOKEN（管理员 PAT）
     是有意的：GITHUB_TOKEN 的推送不触发任何 workflow，AI 修复后的 head
     必须重触发 pr-validate 门禁重新裁决；bot 名下 bump-* 分支被 pr-validate
     拦进 action_required 的场景由 automerge-autobump.yml 的小时扫描自动
     approve（与 bottle 回写 push 同一套兜底）
  5. 报告发 PR 评论，标签按结果换成 ai-success / ai-failed

安全边界（与官方一致）：容器内跑的是 AI 自主生成的命令 + PR 自带代码，只向
容器传 DEEPSEEK_API_KEY（dsh 必需）一个密钥，且经 0600 env-file 注入（不出
现在进程列表）；BOT_PUSH_TOKEN / GH_TOKEN 只在 host 侧使用。fork PR 在
workflow 层直接跳过（fork 代码不进带密钥的 job，同 fork-pr-gate.yml 的规矩；
fork PR 的改动经 fork-pr-gate 开的同仓替换 PR 进来，不受影响）。
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

# 触发标签与运行状态标签（与 pr-validate 的 request-ci/ci-passed/ci-failed 语义对称，
# 命名沿用官方 ai_bump.py）
REQUEST_LABEL = "request-ai-bump"
AI_RUNNING_LABEL = "ai-running"
AI_SUCCESS_LABEL = "ai-success"
AI_FAILED_LABEL = "ai-failed"
# 开跑时摘掉的旧状态标签：ci-failed 描述的是 AI 改动前的旧代码，留着会和
# ai-success/ai-failed 同框打架（官方同款处理）
STALE_LABELS = [REQUEST_LABEL, AI_RUNNING_LABEL, AI_SUCCESS_LABEL, AI_FAILED_LABEL, "ci-failed"]

# workflow 的 Ensure labels 步骤负责创建，这里只留颜色约定做单一事实源
LABEL_COLORS = {
    REQUEST_LABEL: "7057ff",
    AI_RUNNING_LABEL: "fbca04",
    AI_SUCCESS_LABEL: "0e8a16",
    AI_FAILED_LABEL: "d93f0b",
}

# 与官方 ai_bump.py 一致的 dsh 配置（deepseek-flash + high reasoning）
SETTINGS_YAML = """\
agent-default-model:
  provider: deepseek-official
  model: deepseek-flash
  reasoningEffort: high
"""

CONTAINER = os.getenv("CONTAINER", "ohos")
TAP_IN_CONTAINER = os.getenv(
    "TAP_IN_CONTAINER",
    "/storage/Users/currentUser/.harmonybrew/Homebrew/Library/Taps/social4hyq/homebrew-core",
)


def run(cmd, **kwargs):
    cmd = [str(c) for c in cmd]
    print("+", sanitize(" ".join(cmd)), flush=True)
    subprocess.run(cmd, check=True, **kwargs)


def sanitize(text):
    """打码命令行中出现的密钥，避免泄进 workflow 日志"""
    for name in ("BOT_PUSH_TOKEN", "DEEPSEEK_API_KEY", "GH_TOKEN", "GITHUB_TOKEN"):
        value = os.getenv(name)
        if value:
            text = text.replace(value, "***")
    return text


def require_env(*names):
    missing = [n for n in names if not os.getenv(n)]
    if missing:
        raise RuntimeError(f"缺少环境变量: {', '.join(missing)}")


def step_summary(text):
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if path:
        with open(path, "a") as f:
            f.write(text + "\n")


def gh(*args, **kwargs):
    run(["gh", *args], **kwargs)


def gh_json(*args):
    res = subprocess.run(["gh", *args], capture_output=True, text=True, check=True)
    return json.loads(res.stdout)


def cexec(env, cmd, env_file):
    # 密钥不能以 -e KEY=value 的形式出现在 docker exec 命令行上，否则会泄进
    # workflow 日志/进程列表；写入 0600 的临时文件，用 --env-file 传入
    fd = os.open(env_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        for key, value in env.items():
            f.write(f"{key}={value}\n")
    try:
        return run(["docker", "exec", "--env-file", env_file, CONTAINER, *cmd])
    finally:
        os.unlink(env_file)


def post_comment(pr_number, body):
    # 走临时文件而不是 --body 参数：报告长度不可控且含任意 markdown
    fd, path = tempfile.mkstemp(suffix=".md")
    with os.fdopen(fd, "w") as f:
        f.write(body)
    try:
        gh("pr", "comment", str(pr_number), "--body-file", path)
    finally:
        os.unlink(path)


def update_pr_labels(pr_number, remove=(), add=()):
    """更新 PR 标签（先删后加）。标签只是状态展示，API 异常不应掩盖流水线真实结果，故只告警不中断"""
    try:
        current = [l["name"] for l in gh_json("pr", "view", str(pr_number), "--json", "labels")["labels"]]
        new = [name for name in current if name not in remove]
        for name in add:
            if name not in new:
                new.append(name)
        if new != current:
            args = ["pr", "edit", str(pr_number)]
            for name in current:
                if name not in new:
                    args += ["--remove-label", name]
            for name in new:
                if name not in current:
                    args += ["--add-label", name]
            print(f"更新 PR#{pr_number} 标签: {current} -> {new}", flush=True)
            gh(*args)
    except Exception as e:
        print(f"[WARN] 更新 PR 标签失败: {e}", file=sys.stderr, flush=True)


def resolve_formula(pr_number):
    """gh 解析 PR：要求恰好改一个 formula（官方同款约束），返回 (formula, subdir, head_branch, title)"""
    pr = gh_json("pr", "view", str(pr_number), "--json", "files,headRefName,title")
    names = [f["path"] for f in pr.get("files", [])]
    formulae = [n for n in names if re.fullmatch(r"Formula/[^/]+/[^/]+\.rb", n)]
    if len(formulae) != 1:
        raise RuntimeError(f"PR 中变更的 formula 数量为 {len(formulae)}，ai-bump 仅支持单个 formula 的 PR")
    _, subdir, filename = formulae[0].split("/")
    return filename[: -len(".rb")], subdir, pr["headRefName"], pr.get("title") or ""


def build_prompt(formula, subdir, report_dir):
    return f"""你现在在一个鸿蒙（OpenHarmony）环境上，里面有个鸿蒙版的 homebrew。我将 {formula} 这个 formula 升级后，它无法构建通过/测试通过，请帮我排查原因并修复。

构建命令：brew install -y -s -v {formula}
测试命令：brew test {formula}

修复完成后，把以下材料放到 {report_dir} 目录下：
1. 定位报告 report.md
2. 改过的 formula 文件
3. 所有补丁文件，包括原有的和新增的（如果存在）
4. 状态文件 status.json

最终输出的目录骨架应该是这样
{report_dir}
  /report.md
  /status.json
  /Formula/{subdir}/{formula}
  /Patches/{formula}

status.json 的格式：
成功：{{"status": "success"}}
失败：{{"status": "failure", "reason": "<一句话说明失败原因>"}}
只有当你确认构建命令和测试命令都通过后，才允许写 success；否则必须写 failure 并说明原因。

注意事项：
1. 升级后对比上游版本 formula，看看上游是不是引入了什么新改动需要同步进来：
   - Homebrew 官方：https://github.com/Homebrew/homebrew-core/raw/refs/heads/main/Formula/{subdir}/{formula}.rb
   - Harmonybrew 官方（若存在同名 formula）：https://gitcode.com/Harmonybrew/homebrew-core/blob/main/Formula/{subdir}/{formula}.rb
2. 升级过程不要抛弃掉原有的鸿蒙适配补丁或者鸿蒙适配的构建参数（部分软件包可能有，不是每个软件包都一定有）
3. 如果需要制作补丁或新增补丁，请参考本 tap 的现有写法：Patches/<formula>/ 编号补丁文件 + formula 内 `patch do file` 挂载（可参考 bun、herdr、opencode@2 的现有补丁）
4. 只允许修改 Formula/ 与 Patches/ 下的内容，不要动仓库里其他任何文件（包括 .github/）
5. 这个报告用来展示在 PR 评论区，因此不宜过长
6. report.md 会被嵌套在评论已有的一级标题之下，因此不要写总标题，也不要使用一级标题（#），正文直接从二级标题（##）开始分节，例如按 `## 现象`、`## 根因`、`## 修复`、`## 验证` 组织
"""


# ========== agent（OHOS 容器内）==========


def brew(*args):
    run(["brew", *args])


def tap_git(tap_dir, *args):
    run(["git", *args], cwd=tap_dir)


def agent_main():
    require_env("DEEPSEEK_API_KEY", "FORMULA_NAME", "FORMULA_SUBDIR", "PR_NUMBER", "TAP_DIR")
    formula = os.environ["FORMULA_NAME"]
    subdir = os.environ["FORMULA_SUBDIR"]
    pr_number = os.environ["PR_NUMBER"]
    tap_dir = os.environ["TAP_DIR"]
    report_dir = f"/root/report-{formula}"

    # 1. 更新 brew。必须在应用 PR 之前做：brew update 会把 bind-mount 的 tap
    #    checkout 重置到 origin/main（build.sh PR #369 的幽灵提交问题），先跑
    #    它再 checkout AI 工作分支，重置就不会吞掉 PR 改动
    brew("update", "--force")

    # 2. 应用 PR：本地 tap = 最新 main + PR 改动。actions/checkout 是 depth 1
    #    浅克隆，bump 分支的分叉点不在本地，unshallow 这两个 ref 才能 rebase
    unfetch = ["--unshallow"] if os.path.exists(os.path.join(tap_dir, ".git", "shallow")) else []
    tap_git(
        tap_dir,
        "fetch",
        *unfetch,
        "origin",
        "+refs/heads/main:refs/remotes/origin/main",
        f"+refs/pull/{pr_number}/head:refs/remotes/pull/{pr_number}/head",
    )
    tap_git(tap_dir, "checkout", "-B", "ai-bump-work", f"refs/remotes/pull/{pr_number}/head")
    try:
        tap_git(tap_dir, "rebase", "origin/main")
    except subprocess.CalledProcessError:
        subprocess.run(["git", "rebase", "--abort"], cwd=tap_dir, check=False)
        raise RuntimeError(f"PR 代码与最新 main 分支存在冲突，rebase 失败")

    # 3. 安装 deepseek-harness（官方 core 已原生提供，含 OHOS 补丁集与 bottle）
    brew("install", "deepseek-harness")

    # 4. 写 dsh 配置
    dsh_dir = os.path.expanduser("~/.dsh")
    os.makedirs(dsh_dir, exist_ok=True)
    with open(os.path.join(dsh_dir, "settings.yaml"), "w") as f:
        f.write(SETTINGS_YAML)

    # 5. 执行一次性 AI 任务
    prompt = build_prompt(formula, subdir, report_dir)
    rc = subprocess.run(["dsh", "--profile", "headless", prompt]).returncode
    print(f"dsh 退出码: {rc}", flush=True)

    # 6. 状态判定：只认 AI 自声明的 success，其余一律按失败处理
    status_file = os.path.join(report_dir, "status.json")
    try:
        with open(status_file) as f:
            status = json.load(f)
    except FileNotFoundError:
        raise RuntimeError(f"AI 任务结束（退出码 {rc}），但未生成 status.json，按失败处理")
    except json.JSONDecodeError as e:
        raise RuntimeError(f"status.json 无法解析（{e}），按失败处理")
    if status.get("status") != "success":
        raise RuntimeError(f"AI 自声明失败：{status.get('reason', '未说明原因')}")
    if not os.path.isfile(os.path.join(report_dir, "report.md")):
        raise RuntimeError("AI 声明成功，但报告中缺少 report.md")
    formula_candidates = [
        os.path.join(report_dir, "Formula", subdir, formula),
        os.path.join(report_dir, "Formula", subdir, formula + ".rb"),
    ]
    if not any(os.path.exists(c) for c in formula_candidates):
        raise RuntimeError("AI 声明成功，但报告中缺少 formula 文件")
    print("[OK] AI 排查完成，状态：success", flush=True)


def run_agent():
    try:
        agent_main()
    except Exception as e:
        # host 侧会来读这个文件收集失败原因
        with open("/root/ai-bump-error.txt", "w") as f:
            f.write(str(e))
        print(f"[FATAL] {e}", file=sys.stderr, flush=True)
        sys.exit(1)


# ========== host（runner 宿主，workflow 默认入口）==========


def read_failure_reason(report_host):
    """尽量从容器和报告中收集失败原因"""
    reasons = []
    res = subprocess.run(
        ["docker", "exec", CONTAINER, "cat", "/root/ai-bump-error.txt"],
        capture_output=True,
        text=True,
    )
    if res.returncode == 0 and res.stdout.strip():
        reasons.append(res.stdout.strip())
    if report_host:
        status_file = os.path.join(report_host, "status.json")
        try:
            with open(status_file) as f:
                status = json.load(f)
            if status.get("reason"):
                reasons.append(f"AI 自声明：{status.get('status')}，{status['reason']}")
        except FileNotFoundError:
            reasons.append("AI 未生成 status.json（可能中途崩溃）")
        except json.JSONDecodeError:
            reasons.append("status.json 内容无法解析")
    return "；".join(reasons) if reasons else "详见 workflow 日志"


def copy_tree_contents(src, dst):
    for entry in os.listdir(src):
        s = os.path.join(src, entry)
        d = os.path.join(dst, entry)
        if os.path.isdir(s):
            shutil.copytree(s, d, dirs_exist_ok=True)
        else:
            shutil.copy2(s, d)


def push_fix(report_host, formula, subdir, head_branch):
    """把报告里的修复搬进 PR 源分支，返回是否发生了推送"""
    require_env("BOT_PUSH_TOKEN")
    repo_dir = tempfile.mkdtemp(prefix="ai-bump-repo-")
    url = f"https://x-access-token:{os.environ['BOT_PUSH_TOKEN']}@github.com/{os.environ['GITHUB_REPOSITORY']}.git"
    git_env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}

    # depth 必须为 2：depth 1 时顶端提交处于浅克隆边界（被视为无父提交），
    # git commit --amend 会产生一个丢失父指针的孤立根提交（官方同款注释）
    run(
        ["git", "clone", "--depth", "2", "--branch", head_branch, url, repo_dir],
        env=git_env,
    )
    run(["git", "config", "user.name", "github-actions[bot]"], cwd=repo_dir)
    run(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"], cwd=repo_dir)

    # formula 文件完全覆盖（兼容 AI 产出目录/带 .rb 文件/不带 .rb 文件三种形态）
    dst_subdir = os.path.join(repo_dir, "Formula", subdir)
    os.makedirs(dst_subdir, exist_ok=True)
    src_entry = os.path.join(report_host, "Formula", subdir, formula)
    src_rb = src_entry + ".rb"
    if os.path.isdir(src_entry):
        copy_tree_contents(src_entry, dst_subdir)
    elif os.path.isfile(src_rb):
        shutil.copy2(src_rb, dst_subdir)
    elif os.path.isfile(src_entry):
        shutil.copy2(src_entry, os.path.join(dst_subdir, formula + ".rb"))
    else:
        raise RuntimeError("报告中未找到 formula 文件")

    # 补丁目录先删除再复制，完全覆盖；AI 没产出 Patches/ 就不动现有补丁
    src_patches = os.path.join(report_host, "Patches", formula)
    if os.path.isdir(src_patches):
        shutil.rmtree(os.path.join(repo_dir, "Patches", formula), ignore_errors=True)
        os.makedirs(os.path.join(repo_dir, "Patches"), exist_ok=True)
        shutil.copytree(src_patches, os.path.join(repo_dir, "Patches", formula))

    run(["git", "add", "-A"], cwd=repo_dir)
    res = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=repo_dir)
    pushed = False
    if res.returncode == 0:
        print("[WARN] 报告内容与源分支当前代码一致，无需推送", flush=True)
    else:
        # 把 AI 修复 amend 进源分支顶端提交：commit message 与原作者保持不变
        # （bump 格式仍过 lint-commit-messages），bump PR 的单提交形状也不破坏。
        # 多提交 PR 时 amend 的是顶端提交，修复同样落在 diff 里，可接受
        run(["git", "commit", "--amend", "--no-edit"], cwd=repo_dir)
        run(["git", "push", "-f", "origin", f"HEAD:{head_branch}"], cwd=repo_dir, env=git_env)
        pushed = True
    return pushed


def host_main():
    require_env("PR_NUMBER", "GH_TOKEN", "DEEPSEEK_API_KEY", "RUN_URL", "GITHUB_REPOSITORY")
    pr_number = os.environ["PR_NUMBER"]
    env_file = os.path.join(tempfile.gettempdir(), f"ai-bump-env-pr{pr_number}")
    # 进程被强杀时 env-file 可能残留，开跑前先清掉（官方同款）
    try:
        os.unlink(env_file)
    except FileNotFoundError:
        pass
    report_host = None

    def fail(message):
        print(f"[FATAL] {message}", file=sys.stderr, flush=True)
        step_summary(f"**ai-bump 失败**（PR #{pr_number}）：{message}")
        update_pr_labels(pr_number, remove=STALE_LABELS, add=[AI_FAILED_LABEL])
        try:
            post_comment(pr_number, f"## AI Bump 执行失败\n\n{message}")
        except Exception as e:
            print(f"[WARN] 失败评论发送失败: {e}", file=sys.stderr, flush=True)
        sys.exit(1)

    try:
        try:
            formula, subdir, head_branch, title = resolve_formula(pr_number)
            # 幂等守卫：触发标签开跑即被摘掉，若已不在（重复 labeled 事件排队
            # 进来的第二次运行 / 手动 rerun）直接跳过，不打结果标签
            labels = [l["name"] for l in gh_json("pr", "view", str(pr_number), "--json", "labels")["labels"]]
            if REQUEST_LABEL not in labels:
                print(f"[SKIP] request-ai-bump 标签已不在 PR#{pr_number} 上（已消费或已重跑），退出", flush=True)
                return
        except Exception as e:
            fail(str(e))
        print(f"formula: {formula} (Formula/{subdir}/)，源分支: {head_branch}", flush=True)
        step_summary(f"**ai-bump**（PR #{pr_number}）：formula `{formula}`，源分支 `{head_branch}`")

        # 标签交接：摘触发标签/旧状态/ci-failed，打 ai-running（官方同款）
        update_pr_labels(pr_number, remove=STALE_LABELS, add=[AI_RUNNING_LABEL])
        try:
            post_comment(pr_number, f"开始使用 AI 修复本 PR 的构建/测试失败。日志：{os.environ['RUN_URL']}")
        except Exception as e:
            print(f"[WARN] 开始评论发送失败: {e}", file=sys.stderr, flush=True)

        # ---- agent 阶段（OHOS 容器内；只传 DEEPSEEK_API_KEY 一个密钥）----
        agent_env = {
            "DEEPSEEK_API_KEY": os.environ["DEEPSEEK_API_KEY"],
            "FORMULA_NAME": formula,
            "FORMULA_SUBDIR": subdir,
            "PR_NUMBER": pr_number,
            "TAP_DIR": TAP_IN_CONTAINER,
        }
        agent_ok = True
        try:
            cexec(agent_env, ["bash", "-lc", f"python3 {TAP_IN_CONTAINER}/.github/scripts/ai_bump.py --agent"], env_file)
        except subprocess.CalledProcessError:
            agent_ok = False

        report_host = os.path.join(tempfile.gettempdir(), f"ai-bump-report-{formula}")
        shutil.rmtree(report_host, ignore_errors=True)
        report_copied = (
            subprocess.run(
                ["docker", "cp", f"{CONTAINER}:/root/report-{formula}", report_host],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )

        if not agent_ok:
            fail(f"AI 排查未成功：{read_failure_reason(report_host if report_copied else None)}")
        if not report_copied:
            fail("AI 声明成功，但容器中未找到报告目录，按失败处理")

        # ---- push 阶段（host 上直接做，官方是第二个容器）----
        try:
            pushed = push_fix(report_host, formula, subdir, head_branch)
        except Exception as e:
            fail(f"推送修复结果失败：{e}")

        with open(os.path.join(report_host, "report.md")) as f:
            report_md = f.read()
        if pushed:
            branch_line = f"修复结果已 force-push 到源分支 `{head_branch}`（amend 进原顶端提交），pr-validate 将重新门禁。"
        else:
            branch_line = "AI 给出的修复与源分支当前代码一致，未产生新提交。"
        try:
            post_comment(pr_number, f"# AI 排查修复报告 - {title or formula}\n\n> {branch_line} 日志：{os.environ['RUN_URL']}\n\n{report_md}")
        except Exception as e:
            fail(f"修复结果已推送，但报告评论发送失败：{e}")

        update_pr_labels(pr_number, remove=[REQUEST_LABEL, AI_RUNNING_LABEL], add=[AI_SUCCESS_LABEL])
        step_summary(f"**ai-bump 成功**（PR #{pr_number}）：修复{'已' if pushed else '无需'}推送，报告已发 PR 评论")
        print("[DONE] ai-bump 完成", flush=True)
    finally:
        shutil.rmtree(report_host, ignore_errors=True)
        try:
            os.unlink(env_file)
        except FileNotFoundError:
            pass


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--agent", action="store_true", help="OHOS 容器内运行：准备 tap 环境并执行 AI 修复")
    parser.add_argument("--host", action="store_true", help="runner host 上运行（默认）：编排 agent 阶段并推送结果/评论")
    args = parser.parse_args()
    if args.agent:
        run_agent()
    else:
        host_main()


if __name__ == "__main__":
    main()
