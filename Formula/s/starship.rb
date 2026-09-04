class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "8c95e8a6c596b29ac192104eae00dd991e8c8fd66083fd2b34d6b223a5803a59"
  license "ISC"
  revision 4
  head "https://github.com/starship/starship.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/starship-v1.26.0-r7"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5d86818030f4bd76cce21220dadfd0cce56fbaab327b1475038f437ad41a6617"
  end

  depends_on "rust" => :build

  # Pulled in transitively (guess_host_triple -> errno 0.2.4, resolves to
  # 0.2.8). This old errno release hand-rolls its own strerror_r FFI binding
  # gated only on target_os = "linux" (not target_env), so it demands the
  # glibc-only __xpg_strerror_r symbol on musl/OHOS too — a bug in errno
  # 0.2.8 itself (last release of that line), unrelated to the libc crate,
  # which already excludes both musl and ohos correctly. guess_host_triple
  # pins `errno = "0.2.4"` (^0.2), so cargo can't be pointed at errno's newer
  # 0.3.x rewrite (different API) via a plain version bump.
  resource "errno" do
    url "https://static.crates.io/crates/errno/errno-0.2.8.crate"
    sha256 "f639046355ee4f37944e44f60642c6f3a7efa3cf6b78c78a0d989a8ce6c396a1"
  end

  def install
    # Disable default features (battery/notify): OHOS has no dbus, no battery API.
    # All remaining deps are pure Rust.
    resource("errno").stage do
      inreplace "src/unix.rs",
        "#[cfg_attr(target_os = \"linux\", link_name = \"__xpg_strerror_r\")]",
        "#[cfg_attr(all(target_os = \"linux\", not(any(target_env = \"musl\", target_env = \"ohos\"))), " \
        "link_name = \"__xpg_strerror_r\")]"
      (buildpath/"vendor/errno").install Dir["*"]
    end
    open("Cargo.toml", "a") { |f| f.puts "[patch.crates-io]\nerrno = { path = \"vendor/errno\" }" }
    # Re-resolve just this package so --locked accepts the patched source.
    # errno@0.2.8, not bare "errno": the dependency tree also carries a
    # separate errno 0.3.14 (a different crate elsewhere in the graph), so
    # the bare name is ambiguous to cargo.
    system "cargo", "update", "--package", "errno@0.2.8", "--precise", "0.2.8"

    # OHOS sandbox uid not in /etc/passwd; whoami::username() returns uid. Inject
    # dlopen(libos_account_ndk.so) → OH_OsAccount_GetName fallback. Returns None
    # transparently if lib/symbol unavailable (same behavior as unpatched).
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

    # OHOS shell init glue bundled as a keg script (upgrades with brew upgrade starship).
    # Guards: TZ (no /etc/localtime, use date +%z), fpath (autoload add-zsh-hook),
    # mathfunc (system zsh lacks module, rewrite __starship_get_time).
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
