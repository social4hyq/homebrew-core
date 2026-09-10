class Codex < Formula
  desc "OpenAI's coding agent that runs in your terminal"
  homepage "https://github.com/openai/codex"
  url "https://github.com/openai/codex/archive/refs/tags/rust-v0.154.0.tar.gz"
  sha256 "1c4cdc3b87ba290b5d110425b4f6ff21663e236580bc760d1e149bd2d9f9519f"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    regex(/^rust[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fe2c7cc3d90f132a1097a117388b6f2ae5e0ac948cbe18f8c0e3c410abfd69ad"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"
  depends_on "ripgrep"

  # Keep the v8 version here consistent with the v8 version in Cargo.toml:
  #   https://github.com/openai/codex/blob/main/codex-rs/Cargo.toml
  resource "v8-archive" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.4.0/librusty_v8_release_aarch64-unknown-linux-musl.a.gz"
    sha256 "422555b85082bff3cdd8b05c30e710177191ce6fb1cb66cd036fac53240a1be8"
  end

  # Keep the v8 version here consistent with the v8 version in Cargo.toml:
  #   https://github.com/openai/codex/blob/main/codex-rs/Cargo.toml
  resource "v8-binding" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.4.0/src_binding_release_aarch64-unknown-linux-musl.rs"
    sha256 "7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506"
  end

  def install
    cd "codex-rs" do
      ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
      ENV["OPENSSL_NO_VENDOR"] = "1"
      ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

      # Clean cargo cache to ensure fresh patches. rm_rf (force) so that
      # partially-deleted dirs left by an interrupted build do not abort the
      # install with Errno::ENOENT (e.g. a half-removed v8-150.4.0 tree).
      cache_dir = "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**"
      rm_rf(Dir.glob("#{cache_dir}/nix-0.29.0"))
      rm_rf(Dir.glob("#{cache_dir}/rustyline-14.0.0"))
      rm_rf(Dir.glob("#{cache_dir}/v8-*"))

      system "cargo", "fetch"

      # Patch nix crate: its cfg condition excludes target_env="musl" but not "ohos",
      # causing cmsg_len() to return usize while the struct field is socklen_t (u32).
      nix_mod = Pathname.glob("#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/nix-0.29.0/src/sys/socket/mod.rs").first
      inreplace nix_mod,
        "not(target_env = \"musl\")",
        "not(any(target_env = \"musl\", target_env = \"ohos\"))"

      # Patch rustyline: ioctl_read_bad! casts TIOCGWINSZ to ioctl_num_type (c_ulong)
      # but libc::ioctl() expects i32. Replace with a direct call.
      rustyline_mod = Pathname.glob(
        "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/rustyline-14.0.0/src/tty/unix.rs",
      ).first
      inreplace rustyline_mod,
        "nix::ioctl_read_bad!(win_size, libc::TIOCGWINSZ, libc::winsize);",
        "unsafe fn win_size(fd: libc::c_int, data: *mut libc::winsize) -> nix::Result<libc::c_int> {
    nix::errno::Errno::result(libc::ioctl(fd, libc::TIOCGWINSZ as i32, data))
}"

      # Deep async nesting + tracing::instrument (exec, cli, app-server, ...)
      # exceeds rustc's default recursion limit (128) on brew's newer rustc
      # (1.98.0 vs upstream's pinned 1.95.0), failing with
      # "error: queries overflow the depth limit!" (query depth 130+).
      # Upstream only sets #![recursion_limit = "256"] in app-server/mcp-server,
      # so raise it on every workspace crate root in one pass; otherwise each
      # newly-compiled crate (exec, cli, code-mode-host, ...) fails in turn.
      Dir.glob(["*/src/lib.rs", "*/src/main.rs", "ext/*/src/lib.rs", "ext/*/src/main.rs"]).each do |crate_root|
        next if File.read(crate_root).include?("recursion_limit")
        inreplace crate_root, /\A/, "#![recursion_limit = \"256\"]\n"
      end

      ENV["RUSTY_V8_ARCHIVE"] = resource("v8-archive").cached_download
      ENV["RUSTY_V8_SRC_BINDING_PATH"] = resource("v8-binding").cached_download

      # Link clang's builtins library (provides __clear_cache needed by V8)
      builtins = Utils.safe_popen_read("clang", "--print-libgcc-file-name").strip
      ENV.append "RUSTFLAGS", "-L #{File.dirname(builtins)} -C link-arg=-l:libclang_rt.builtins.a"

      # Codex is a CLI tool, not a high-performance application.
      # Disable the upstream project's thin LTO which adds 60+ minutes to link time.
      inreplace "Cargo.toml" do |s|
        s.gsub! 'lto = "thin"', "lto = false"
      end

      # Limit build parallelism to half of available CPU cores to prevent OOM errors
      jobs = [(ENV.make_jobs.to_i / 2), 1].max

      cargo_args = %W[
        --jobs
        #{jobs}
        --locked
        --root=#{prefix}
      ]

      system "cargo", "install", *cargo_args, "--path=cli", "--bin", "codex"
      system "cargo", "install", *cargo_args, "--path=code-mode-host", "--bin", "codex-code-mode-host"
    end
  end

  test do
    system bin/"codex", "--help"
    system bin/"codex-code-mode-host", "--help"
  end
end
