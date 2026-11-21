class Zcode < Formula
  desc "AI coding workbench: terminal agent with TUI and web IDE"
  homepage "https://github.com/zai-org/ZCode"
  # Pin the public main snapshot; its version comes from package.json.
  url "https://github.com/zai-org/ZCode.git",
      revision: "fec975905a2abd4c07e35c40d51fa097a2258ec9"
  version "3.18.2"
  license "Apache-2.0"
  revision 2
  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-v3.18.2-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "40c43eddfe7879538dc88c845c8ec9a0c3776c0b4fd2b8668b108f556ef444df"
  end

  depends_on "node" => :build
  depends_on "pnpm" => :build
  depends_on "python@3.14" => :build
  depends_on "bun"

  patch do
    file "Patches/zcode/0001-ohos-sea-targets.patch"
  end

  patch do
    file "Patches/zcode/0002-bun-node-sea-guards.patch"
  end

  patch do
    file "Patches/zcode/0003-ohos-skip-desktop-electron-runtime.patch"
  end

  patch do
    file "Patches/zcode/0004-web-login-server-oauth.patch"
  end

  patch do
    file "Patches/zcode/0005-ohos-frozen-lockfile.patch"
  end

  deny_network_access! :test

  def install
    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV["ELECTRON_SKIP_BINARY_DOWNLOAD"] = "1"

    system "pnpm", "install", "--frozen-lockfile"

    # turbo ships no openharmony binary; run the build steps in order.
    system "pnpm", "--filter", "@zcode/cli...", "--filter", "@zcode/server",
           "--filter", "@zcode/web", "--filter", "!@zcode/cli", "build"
    cd "apps/zcode-cli/packages/cli" do
      system "node", "scripts/build.mjs"
    end
    # packages/shared has no build script; SEA staging requires its dist.
    system "node_modules/.bin/tsc", "-p", "packages/shared"

    system "node", "scripts/build-zcode.mjs", "--skip-build",
           "--base-url", "https://example.invalid/zcode/"

    staging = buildpath/"staging"
    staging.mkpath
    system "tar", "-xzf", "dist/zcode/releases/#{version}/zcode-#{version}.tar.gz", "-C", staging
    app = staging/"zcode"

    # One physical opentui copy, or the react reconciler's instanceof
    # checks fail across the two override-resolved module trees.
    rm_r app/"agent/node_modules/@opentui/core"
    (app/"agent/node_modules/@opentui/core").make_symlink "../@mbears/opentui-core"

    libexec.install app
    (bin/"zcode").write_env_script formula_opt_bin("bun")/"bun", libexec/"zcode/bin/zcode.mjs", {}
  end

  def caveats
    <<~EOS
      zcode runs on the bun runtime (full interactive TUI; Node.js cannot
      run the TUI here because HarmonyOS denies libffi the executable
      anonymous memory its JS-to-native callbacks need).

      The web IDE's embedded terminal is unavailable because node-pty
      cannot spawn child processes under bun on OpenHarmony. Browser
      automation (playwright-core) has no openharmony build in its upstream
      loader, so browser-use skills are unavailable on this platform. CUA
      screen capture is disabled (koffi does not build for OHOS arm64).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zcode --version")
    assert_match "Usage:", shell_output("#{bin}/zcode --help")
    doctor = shell_output("#{bin}/zcode doctor")
    assert_match "platform: openharmony/arm64", doctor
    assert_match "default artifact: node-bundle", doctor
  end
end
