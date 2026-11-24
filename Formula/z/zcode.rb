class Zcode < Formula
  desc "AI coding workbench: terminal agent with TUI and web IDE"
  homepage "https://github.com/zai-org/ZCode"
  # Pin the public main snapshot; its version comes from package.json.
  url "https://github.com/zai-org/ZCode.git",
      revision: "a4b4445141eb7d3b3e99eada9292775383bfc44e"
  version "4.0.0"
  license "Apache-2.0"
  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-v3.18.2-r6"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a9f6489ca3e40674d4799134d1f92f21c26888a9089f9d9cd800ea2f71230876"
  end

  depends_on "node" => :build
  depends_on "pnpm" => :build
  depends_on "python@3.14" => :build
  depends_on "bun"

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/zcode/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
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

    # The cross-platform release scripts restore other native prebuilds; ship only OHOS.
    rm_r Dir[app/"node_modules/node-pty/prebuilds/{darwin-*,linux-*,win32-*}"]

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
    assert_path_exists libexec/"zcode/node_modules/node-pty/prebuilds/openharmony-arm64/pty.node"
    refute_path_exists libexec/"zcode/node_modules/node-pty/prebuilds/linux-x64/pty.node"
  end
end
