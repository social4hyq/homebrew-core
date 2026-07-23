class Codex < Formula
  desc "OpenAI's coding agent that runs in your terminal"
  homepage "https://github.com/openai/codex"
  url "https://github.com/openai/codex/archive/refs/tags/rust-v0.145.0.tar.gz"
  sha256 "7126822e9148f20297434f0e302b811f5eea8700879686a5960d4a6444c2e369"
  license "Apache-2.0"

  livecheck do
    url :url
    regex(/^rust[._-]v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e8c92ab81e4bf30fa91ee9031a16fa58225e2c9ba3ea893c596df4949e5734b4"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"
  depends_on "ripgrep"

  resource "v8-archive" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.2.0/librusty_v8_release_aarch64-unknown-linux-musl.a.gz"
    sha256 "37bbd594303784d644abce3b1c19353a48d7b6ccee2771a4b0b6db748d2ed02e"
  end

  resource "v8-binding" do
    url "https://github.com/denoland/rusty_v8/releases/download/v150.2.0/src_binding_release_aarch64-unknown-linux-musl.rs"
    sha256 "7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506"
  end

  def install
    cd "codex-rs" do
      ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
      ENV["OPENSSL_NO_VENDOR"] = "1"
      ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

      # Clean cargo cache to ensure fresh patches
      cache_dir = "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**"
      rm_r(Dir.glob("#{cache_dir}/nix-0.29.0"))
      rm_r(Dir.glob("#{cache_dir}/rustyline-14.0.0"))
      rm_r(Dir.glob("#{cache_dir}/v8-*"))

      # Upgrade v8 crate to 150.2.0 (only version with aarch64-musl prebuilt)
      inreplace "Cargo.toml",
        'v8 = "=149.2.0"',
        'v8 = "=150.2.0"'

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
        --path=cli
        --bin
        codex
      ]

      system "cargo", "install", *cargo_args
    end
  end

  test do
    system bin/"codex", "--help"
  end
end
