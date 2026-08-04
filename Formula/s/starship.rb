class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "8c95e8a6c596b29ac192104eae00dd991e8c8fd66083fd2b34d6b223a5803a59"
  license "ISC"
  revision 2
  head "https://github.com/starship/starship.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/starship-v1.26.0-r4"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "aa8748783aa25ad7d4cfc91df90bb75a5779d403213701fd284c3cea5b8398d0"
  end

  depends_on "rust" => :build

  def install
    # OHOS 适配：关闭 default features（battery + notify）。
    # notify → notify-rust → dbus：OHOS 无 dbus 桌面通知服务，且 tap 无 dbus formula。
    # battery：OHOS 电池 API 语义不同，终端 prompt 无需。
    # 去掉两者后，全部依赖均为纯 Rust crate（gix 用 zlib-rs 纯 Rust 后端），无需系统库。
    #
    # OHOS 链接修复：rust libc crate 对 OHOS target 将 strerror_r 的 link_name
    # 声明为 __xpg_strerror_r（glibc XPG 变体），但 OHOS musl 动态 libc 不导出
    # 该符号（仅静态 libc.a 有弱别名），最终链接报 undefined。用 rustc 生成一个
    # 转发到 strerror_r 的 .o，经 RUSTFLAGS 注入所有链接阶段（含 build script），
    # 无需 C 编译器，也就不必引入 ohos-sdk build 依赖。
    (buildpath/"strerror_shim.rs").write <<~RUST
      #[no_mangle]
      pub extern "C" fn __xpg_strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32 {
          extern "C" { fn strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32; }
          unsafe { strerror_r(errnum, buf, buflen) }
      }
    RUST
    system "rustc", "--edition", "2021", "--crate-type", "staticlib", "--emit", "obj",
           "-O", "strerror_shim.rs", "-o", "strerror_shim.o"
    ENV["RUSTFLAGS"] = "-C link-arg=#{buildpath}/strerror_shim.o"

    # OHOS 应用沙箱：进程 uid 是沙箱 uid（2002xxxx），不在 /etc/passwd，username 模块
    # 依赖的 whoami::username()（getpwuid 路径）拿不到真名，回退的 $USER 又被终端设成
    # 数字（如 "100"），最终 prompt 显示成 uid。真实账户名只有系统库
    # libos_account_ndk.so 的 OH_OsAccount_GetName（API 12+）能给。
    #
    # 两处 inreplace 都只锚定不易变的最小单元：插入点锚在 `pub fn module` 这个公开
    # 函数签名上；替换点只换 `whoami::username()` 这一个调用表达式本身（返回类型
    # 不变，靠类型推断跟 whoami 的 Result 错误类型对齐），后面 .inspect_err/.ok/
    # .or_else 整条链原样不动。库/符号不存在时（如容器无 account 服务）返回
    # None，透明回退到原有 whoami/$USER 逻辑，行为与打补丁前一致。
    inreplace "src/modules/username.rs",
      "pub fn module<'a>(context: &'a Context) -> Option<Module<'a>> {",
      <<~RUST + "pub fn module<'a>(context: &'a Context) -> Option<Module<'a>> {"
        fn ohos_account_username() -> Option<String> {
            unsafe extern "C" {
                fn dlopen(file: *const u8, flags: i32) -> *mut core::ffi::c_void;
                fn dlsym(handle: *mut core::ffi::c_void, name: *const u8) -> *mut core::ffi::c_void;
            }
            unsafe {
                let handle = dlopen(c"libos_account_ndk.so".as_ptr().cast(), 2 /* RTLD_NOW */);
                if handle.is_null() {
                    return None;
                }
                let sym = dlsym(handle, c"OH_OsAccount_GetName".as_ptr().cast());
                if sym.is_null() {
                    return None;
                }
                let get_name: extern "C" fn(*mut u8, usize) -> i32 = core::mem::transmute(sym);
                let mut buf = [0u8; 256];
                if get_name(buf.as_mut_ptr(), buf.len()) != 0 {
                    return None;
                }
                let end = buf.iter().position(|&b| b == 0).unwrap_or(buf.len());
                core::str::from_utf8(&buf[..end]).ok().filter(|s| !s.is_empty()).map(str::to_string)
            }
        }

      RUST

    inreplace "src/modules/username.rs",
      "whoami::username()",
      "ohos_account_username().map(Ok).unwrap_or_else(whoami::username)"

    system "cargo", "install", *std_cargo_args, "--no-default-features"

    generate_completions_from_executable(bin/"starship", "completions")

    # OHOS shell 初始化胶水，打包成一个自带脚本而不是塞进 caveats 让用户手抄：
    # 手抄的块一旦贴进各台机器的 dotfile 就冻结了，以后发现新坑得逐台改；装进
    # formula 自己的 share/ 下，胶水随 `brew upgrade starship` 一起升级，新机
    # ~/.zshrc 只需一行 `source`。三个坑各自带守卫，缺前提就跳过：
    #   - TZ：本机没有 /etc/localtime、也没有逐时区 zoneinfo（只有 Android 格式
    #     tzdata blob），IANA 名字不生效，只有 POSIX 偏移串管用，运行时用
    #     `date +%z` 现推，取不到就不设（不比不 source 更糟）
    #   - fpath：系统 zsh（HiShell）没把 zsh 自带函数目录接进 fpath，autoload
    #     会找不到 add-zsh-hook；brew zsh 本来就有，这里幂等去重
    #   - mathfunc：系统 zsh 无此模块，starship init 生成的 __starship_get_time
    #     调 int(rint(...)) 会报错，改写成纯算术版本（必须放在 starship init
    #     之后，否则会被 init 自己定义的版本覆盖回去）
    pkgshare.mkpath
    (pkgshare/"ohos-init.zsh").write <<~ZSH
      # harmonybrew-core `starship` formula 自带的 OHOS shell 初始化胶水。
      # 由 formula 生成，不要手改——升级走 `brew upgrade starship`。

      _starship_ohos_setup_tz() {
          [[ -n ${TZ:-} ]] && return
          local off sign hh mm
          off=$(date +%z 2>/dev/null) || return
          [[ $off == [+-][0-9][0-9][0-9][0-9] ]] || return
          sign=${off[1]} hh=${off[2,3]} mm=${off[4,5]}
          hh=${hh#0}
          [[ -z $hh ]] && hh=0
          # POSIX TZ 的符号习惯是反的：本地时间 = UTC + 8 要写成 "UTC-8"。
          [[ $sign == + ]] && sign=- || sign=+
          if [[ $mm == 00 ]]; then
              export TZ="UTC${sign}${hh}"
          else
              export TZ="UTC${sign}${hh}:${mm}"
          fi
      }
      _starship_ohos_setup_tz
      unset -f _starship_ohos_setup_tz

      _starship_ohos_funcs="#{HOMEBREW_PREFIX}/share/zsh/functions"
      if [[ -d $_starship_ohos_funcs ]] && (( ! ${fpath[(Ie)$_starship_ohos_funcs]} )); then
          fpath=("$_starship_ohos_funcs" $fpath)
      fi
      unset _starship_ohos_funcs

      autoload -Uz compinit && compinit -u 2>/dev/null
      eval "$(starship init zsh)" 2>/dev/null

      if ! zmodload -e zsh/mathfunc 2>/dev/null; then
          zmodload zsh/datetime 2>/dev/null
          __starship_get_time() {
              typeset -gi STARSHIP_CAPTURED_TIME
              (( STARSHIP_CAPTURED_TIME = EPOCHREALTIME * 1000 ))
          }
      fi
    ZSH
  end

  def caveats
    <<~CAVEATS
      Set up starship on OHOS (copy-paste this whole line):

        echo 'source "#{opt_pkgshare}/ohos-init.zsh"' >> ~/.zshrc && source ~/.zshrc

      This one line replaces the old hand-copied OHOS init block — the glue
      (timezone, fpath, mathfunc fallback) now lives in the keg and upgrades
      with `brew upgrade starship`.
    CAVEATS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/starship --version")
    ENV["STARSHIP_CONFIG"] = ""
    assert_match "❯", shell_output("#{bin}/starship module character")
  end
end
