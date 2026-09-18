class Rustup < Formula
  desc "Rust toolchain installer"
  homepage "https://rust-lang.github.io/rustup/"
  url "https://github.com/rust-lang/rustup/archive/refs/tags/1.29.1.tar.gz"
  sha256 "00f79a02275fd0252be6928d7a44f96bfba706a0cc47a0c85557aa4a875d1181"
  license any_of: ["Apache-2.0", "MIT"]
  revision 1
  compatibility_version 1
  head "https://github.com/rust-lang/rustup.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2925d137ae1d580b4add3a1cb001ce113a9341932064c6ca7d316aa2441595c1"
  end

  keg_only "it conflicts with rust"

  depends_on "rust" => :build
  depends_on "cmake" => :build
  depends_on "patchelf"
  depends_on "zlib-ng-compat"

  uses_from_macos "curl"
  uses_from_macos "xz"

  on_linux do
    depends_on "pkgconf" => :build
    depends_on "openssl@3"
  end

  # ═══════════════════════════════════════════════════════════════════
  # HarmonyOS patches
  #
  # Problem: On HarmonyOS PC, the kernel refuses to exec/dlopen an ELF
  # without a .codesign section, so downloaded Rust toolchain binaries
  # must be code-signed after install.
  #
  #   0001: Vendored selfsign.rs (byte-identical to ohos-selfsign, kept in
  #         its own patch so it can be upgraded independently)
  #   0002: Adapt vendored selfsign.rs to an importable library
  #         (drop main(), export API)
  #   0003: Post-install toolchain hook (rpath, SSL_CERT_FILE wrapper,
  #         self-sign every ELF with the vendored selfsign)
  # ═══════════════════════════════════════════════════════════════════

  patch do
    file "Patches/rustup/0001-vendor-selfsign-rs.patch"
  end

  patch do
    file "Patches/rustup/0002-export-selfsign-lib.patch"
  end

  patch do
    file "Patches/rustup/0003-ohos-post-install.patch"
  end

  def install
    # Work around superenv breaking aws-lc-sys `-O0` needed to build CPU Jitter RNG
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"

    system "cargo", "install", *std_cargo_args(features: "no-self-update")

    # Upstream installs this binary as `rustup-init`, but Homebrew packages
    # `rustup` directly and should not provide a separate installer entrypoint.
    mv bin/"rustup-init", bin/"rustup"

    # Move the real binary to libexec and wrap bin/rustup to inject:
    #   RUSTUP_OVERRIDE_HOST_TRIPLE            -> force the ohos host triple so
    #                                             rustup pulls the ohos toolchain
    #   SSL_CERT_FILE                          -> use the openssl@3 cert.pem
    #   RUSTUP_OVERRIDE_UNIX_FALLBACK_SETTINGS -> default toolchain = stable
    #   RUSTUP_OHOS_RPATH                      -> rpath dirs for post-processing
    #   RUSTUP_DIST_SERVER / RUSTUP_UPDATE_ROOT -> Alibaba Cloud mirror
    libexec_bin = libexec/"bin"
    libexec_bin.install bin/"rustup"

    rpath = [Formula["openssl@3"].opt_lib, Formula["zlib-ng-compat"].opt_lib].join(":")

    (bin/"rustup").write <<~EOS
      #!/bin/sh
      export RUSTUP_OVERRIDE_HOST_TRIPLE="${RUSTUP_OVERRIDE_HOST_TRIPLE:-aarch64-unknown-linux-ohos}"
      export SSL_CERT_FILE="${SSL_CERT_FILE:-#{HOMEBREW_PREFIX}/etc/openssl@3/cert.pem}"
      export RUSTUP_OVERRIDE_UNIX_FALLBACK_SETTINGS="${RUSTUP_OVERRIDE_UNIX_FALLBACK_SETTINGS:-#{pkgetc}/settings.toml}"
      export RUSTUP_OHOS_RPATH="#{rpath}"
      # Use Chinese mirror by default (Alibaba Cloud).
      export RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://mirrors.aliyun.com/rustup}"
      export RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://mirrors.aliyun.com/rustup/rustup}"
      # Preserve argv[0]: bin/cargo, bin/rustc ... symlink to this wrapper, and
      # rustup dispatches as a proxy based on the invoked name.
      exec -a "$0" "#{libexec_bin}/rustup" "$@"
    EOS
    chmod 0755, bin/"rustup"

    %w[cargo cargo-clippy cargo-fmt cargo-miri clippy-driver rls rust-analyzer
       rust-gdb rust-gdbgui rust-lldb rustc rustdoc rustfmt].each do |name|
      bin.install_symlink bin/"rustup" => name
    end

    (buildpath/"settings.toml").write <<~TOML
      default_toolchain = "stable"
    TOML
    pkgetc.install "settings.toml"

    generate_completions_from_executable(libexec/"bin/rustup", "completions", shells: [:bash, :zsh, :fish, :pwsh])
    [:bash, :zsh].each do |shell|
      generate_completions_from_executable(
        libexec/"bin/rustup", "completions", shell.to_s, "cargo",
        shells: [shell], base_name: "cargo", shell_parameter_format: :none
      )
    end
  end

  def post_install
    (HOMEBREW_PREFIX/"bin").install_symlink bin/"rustup"
    (HOMEBREW_PREFIX/"etc/bash_completion.d").install_symlink bash_completion/"rustup"
    (HOMEBREW_PREFIX/"share/zsh/site-functions").install_symlink zsh_completion/"_rustup"
    (HOMEBREW_PREFIX/"share/fish/vendor_completions.d").install_symlink fish_completion/"rustup.fish"
    (HOMEBREW_PREFIX/"share/pwsh/completions").install_symlink pwsh_completion/"_rustup.ps1"

    # Remove the old Homebrew-created symlink during upgrades, but leave any
    # user-managed `rustup-init` file alone.
    rustup_init = HOMEBREW_PREFIX/"bin/rustup-init"
    rustup_init.unlink if rustup_init.symlink? && rustup_init.readlink.to_s.match?(%r{(?:Cellar|opt)/rustup/})
  end

  def caveats
    <<~EOS
      To use rustup, ensure you have "$(brew --prefix rustup)/bin" in your $PATH:
        https://rust-lang.github.io/rustup/installation/already-installed-rust.html

      This formula no longer provides `rustup-init`.
    EOS
  end

  test do
    ENV["CARGO_HOME"] = testpath/".cargo"
    ENV["RUSTUP_HOME"] = testpath/".rustup"
    ENV.prepend_path "PATH", bin

    assert_match "stable", shell_output("#{bin}/rustup default")
    assert_match "stable", shell_output("#{bin}/rustc --version 2>&1")

    system bin/"cargo", "new", "--bin", "./app"
    cd "app" do
      system bin/"cargo", "fmt"
      system bin/"rustc", "src/main.rs"
      assert_equal "Hello, world!", shell_output("./main").chomp
      assert_empty shell_output("#{bin}/cargo clippy")
    end

    # Check that Homebrew only exposes the packaged `rustup` entrypoint.
    refute_path_exists bin/"rustup-init"

    # Check for stale symlinks.
    # Symlink the wrapper (not the real binary) so the OHOS environment
    # (host triple, rpath, mirror) is injected; otherwise rustup-init would
    # detect the GNU host triple and pull the wrong toolchain.
    testpath.install_symlink bin/"rustup" => "rustup-init"
    system testpath/"rustup-init", "-y"
    bins = bin.glob("*").to_set(&:basename)
    expected = testpath.glob(".cargo/bin/*").to_set(&:basename)
    assert (extra = bins - expected).empty?, "Symlinks need to be removed: #{extra.join(",")}"
    assert (missing = expected - bins).empty?, "Symlinks need to be added: #{missing.join(",")}"
  end
end
