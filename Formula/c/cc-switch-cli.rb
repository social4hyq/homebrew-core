class CcSwitchCli < Formula
  desc "All-in-one assistant tool for Claude Code, Codex, Gemini, OpenCode and OpenClaw"
  homepage "https://github.com/SaladDay/cc-switch-cli"
  url "https://github.com/SaladDay/cc-switch-cli/archive/refs/tags/v5.10.5.tar.gz"
  sha256 "995bb09b38534659301d94ac675b7c7e2e860e3bf0ce41d5fc430c76b7b61c06"
  license "MIT"
  head "https://github.com/SaladDay/cc-switch-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57e2acdfdf5553a4685d83cf74bb77f514e32d3528e13f8ee9ea7d48fd156383"
  end

  depends_on "rust" => :build

  # Upstream rejects a managed config directory that is writable by group or
  # other users. OpenHarmony user storage (/storage/Users/currentUser)
  # creates directories group-writable, so cc-switch cannot run there; relax
  # the check to only reject directories writable by other users.
  patch do
    file "Patches/cc-switch-cli/0001-relax-config-dir-permissions.patch"
  end

  def install
    # Fetch all dependencies first so rquickjs-sys sources exist in the cache
    system "cargo", "fetch", "--manifest-path", "src-tauri/Cargo.toml"

    # rquickjs-sys 0.8.1 does not ship pre-generated bindings for the OHOS
    # target, so its build.rs prints a warning and lib.rs fails to include
    # bindings/aarch64-unknown-linux-ohos.rs. OpenHarmony's libc is musl-based,
    # so reuse the musl bindings, which are ABI-compatible.
    bindings_dir = Pathname.glob(
      "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/rquickjs-sys-0.8.1/src/bindings",
    ).first
    cp bindings_dir/"aarch64-unknown-linux-musl.rs", bindings_dir/"aarch64-unknown-linux-ohos.rs"

    system "cargo", "install", *std_cargo_args(path: "src-tauri")
    generate_completions_from_executable(bin/"cc-switch", "completions")
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/".config").to_s
    ENV["CODEX_HOME"] = (testpath/".codex").to_s
    ENV["CC_SWITCH_CONFIG_DIR"] = (testpath/"cc-switch").to_s
    ENV["ANTHROPIC_API_KEY"] = "cc-switch-test-api-key"
    ENV["CC_SWITCH_BREW_TEST"] = "1"

    output = shell_output("#{bin}/cc-switch env check -a claude")
    assert_match "ANTHROPIC_API_KEY", output
    assert_match "cc-switch-test-api-key", output
    assert_match "conflict", output
  end
end
