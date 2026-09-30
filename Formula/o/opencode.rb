class Opencode < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v2.0.20.tar.gz"
  sha256 "e8bc8af7f8f2df976740fc0a3a0564d6d7b34b9389d921ae0007fa2f49c1c236"
  license "MIT"
  revision 3
  version_scheme 1

  livecheck do
    url :stable
    regex(/^v(2\.\d+\.\d+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v2.0.20-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b3457e0d8172ab76770d247d33c6d6c54ad750fd6f15f2c41354d3cd5e57d225"
  end

  depends_on "bun" => :build
  depends_on "python@3.14" => :build
  depends_on "rust" => :build
  depends_on "ripgrep"

  conflicts_with "opencode-v1", because: "both install an opencode binary"

  # Version must match `@opencode-ai/pty` in packages/cli/package.json
  resource "opencode-pty" do
    url "https://github.com/anomalyco/opencode-pty/archive/refs/tags/v0.1.13.tar.gz"
    sha256 "87f86d91eae5b77f9bc1e3dd76c51f85e8c6ff645a60a373f027943557d8b849"
  end

  # Commit must match `GHOSTTY_COMMIT` in the `libghostty-vt-sys` crate's build.rs
  resource "ghostty" do
    url "https://github.com/ghostty-org/ghostty/archive/a887df42c56f6de86c0fe6da9c4eeca37931e083.tar.gz"
    sha256 "fb4b2f9ffa0af125983041fdbe4ef94d3fa79fb9f2d22b9c213c0e3847a866b6"
  end

  # Ghostty's minimum_zig_version is 0.15.2; this tap has no zig formula.
  resource "zig" do
    url "https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz"
    sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  end

  # portable-pty's nix 0.28 predates OHOS support (nix >= 0.30 has it).
  resource "portable-pty" do
    url "https://static.crates.io/crates/portable-pty/0.9.0/download"
    sha256 "b4a596a2b3d2752d94f51fac2d4a96737b8705dddd311a32b9af47211f08671e"
  end

  patch do
    file "Patches/opencode/0001-update-package-json.patch"
  end

  patch do
    file "Patches/opencode/0002-update-bun-lock.patch"
  end

  patch do
    file "Patches/opencode/0003-update-filesystem-watcher.patch"
  end

  patch do
    file "Patches/opencode/0005-update-server-connection.patch"
  end

  patch do
    file "Patches/opencode/0006-update-build-target.patch"
  end

  patch do
    file "Patches/opencode/0007-allow-local-pty-binary.patch"
  end

  def install
    resource("zig").stage(buildpath/"zig-toolchain")
    # Native zig picks the OHOS SDK sysroot (no bits/alltypes.h); use its bundled musl instead.
    (buildpath/"zig-bin/zig").write <<~SH
      #!/bin/sh
      exec #{buildpath}/zig-toolchain/zig "$@" -Dtarget=aarch64-linux-musl
    SH
    chmod 0755, buildpath/"zig-bin/zig"
    ENV.prepend_path "PATH", buildpath/"zig-bin"
    ENV["ZIG_GLOBAL_CACHE_DIR"] = (HOMEBREW_CACHE/"opencode-zig-global-cache").to_s

    # Build the persistent PTY helper from source instead of embedding the prebuilt npm binary
    (buildpath/"ghostty").install resource("ghostty")
    ENV["GHOSTTY_SOURCE_DIR"] = buildpath/"ghostty"
    (buildpath/"portable-pty").install resource("portable-pty")
    inreplace "portable-pty/Cargo.toml", 'version = "0.28"', 'version = "0.31"'
    resource("opencode-pty").stage do
      inreplace "Cargo.toml" do |s|
        s.gsub! 'nix = { version = "0.28"', 'nix = { version = "0.31"'
        s.gsub! 'portable-pty = "0.9.0"', %Q(portable-pty = { path = "#{buildpath}/portable-pty" })
      end
      system "cargo", "fetch"
      system "cargo", "install", *std_cargo_args(root: buildpath/"opencode-pty")
    end
    ENV["OPENCODE_PTY_BIN"] = buildpath/"opencode-pty/bin/opencode-pty"

    ENV["OPENCODE_VERSION"] = version.to_s
    ENV["OPENCODE_CHANNEL"] = "latest"

    # Fix server errors when building with Bun 1.4.2 by disabling splitting
    # https://github.com/anomalyco/opencode/issues/48645
    # https://github.com/NixOS/nixpkgs/issues/563241
    inreplace "packages/cli/script/build.ts", "splitting: true,", "splitting: false,"

    # 0001 swaps in @ohos-npm-ports overrides, so bun.lock can't stay frozen
    system "bun", "install", "--ignore-scripts"

    cd "packages/cli" do
      system "bun", "--bun", "./script/build.ts", "--single", "--skip-install"
      bin.install Pathname.pwd.glob("dist/cli-*/bin/opencode").first
    end

    generate_completions_from_executable(bin/"opencode", "--completions", base_name: "opencode")
  end

  test do
    ENV["OPENCODE_DISABLE_AUTOUPDATE"] = "1"
    ENV["OPENCODE_DISABLE_MODELS_FETCH"] = "1"

    assert_match version.to_s, shell_output("#{bin}/opencode --version")

    (testpath/"opencode.json").write <<~JSON
      { "agent": { "brewtest": { "description": "Homebrew test agent", "prompt": "hi" } } }
    JSON
    # The standalone server listens on localhost, so network access can't be denied here
    entries = JSON.parse(shell_output("#{bin}/opencode api --standalone config.get"))
    project = entries.find { |entry| entry["path"] == (testpath/"opencode.json").realpath.to_s }
    assert_equal "hi", project.dig("info", "agents", "brewtest", "system")
  end
end
