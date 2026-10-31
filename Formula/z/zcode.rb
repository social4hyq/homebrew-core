class Zcode < Formula
  require "yaml"

  desc "AI coding workbench: terminal agent with TUI and web IDE"
  homepage "https://github.com/zai-org/ZCode"
  # Pin the public main snapshot; its version comes from package.json.
  url "https://github.com/zai-org/ZCode.git",
      revision: "a60ba6a7e5a06742270ca605f5d2cc2766afa7e1"
  version "3.17.1"
  license "Apache-2.0"
  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-v3.17.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d7c4d8ec79660397f8c198c8d677171c17166113bf901d1180121140abaa2bf"
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

  deny_network_access! :test

  def install
    pkg_json = JSON.parse(File.read("package.json"))
    ws = YAML.safe_load_file("pnpm-workspace.yaml")
    # pnpm 12 reads linker and override settings from the workspace file.
    ws["nodeLinker"] = "hoisted"
    ws["overrides"] = {
      "node-pty"              => "npm:@ohos-ports/node-pty@1.1.0-beta.4",
      "@mbears/opentui-core"  => "npm:@ohos-npm-ports/opentui-core@0.5.8-2",
      "@mbears/opentui-react" => "npm:@opentui/react@0.5.8",
      "@opentui/core"         => "npm:@ohos-npm-ports/opentui-core@0.5.8-2",
      "esbuild"               => "0.28.2",
      "tailwindcss"           => "4.3.3",
      "@tailwindcss/vite"     => "4.3.3",
      "@tailwindcss/oxide"    => "npm:@ohos-npm-ports/tailwindcss-oxide@4.3.3-2",
      "lightningcss"          => "npm:@ohos-npm-ports/lightningcss@1.33.0-1",
    }.merge(pkg_json.dig("pnpm", "overrides") || {})

    # CUA capture is unavailable; allow the replacement PTY package to build.
    ws["allowBuilds"]["koffi"] = false
    ws["allowBuilds"]["@ohos-ports/node-pty"] = true
    File.write("pnpm-workspace.yaml", YAML.dump(ws))

    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV["ELECTRON_SKIP_BINARY_DOWNLOAD"] = "1"

    # Overrides re-resolve the lockfile; CI would freeze the stale one.
    system "pnpm", "install", "--no-frozen-lockfile"

    # Avoid recursion in esbuild's WASM launcher when stderr is a build log.
    esbuild_shim = buildpath/"node_modules/@esbuild/openharmony-arm64/bin/esbuild"
    if esbuild_shim.exist? && esbuild_shim.read.exclude?("SyncWriteStream")
      inreplace esbuild_shim,
                /if \(fd === process\.(std(?:out|err))\.fd\) return/,
                'if (fd === process.\1.fd && process.\1.constructor.name !== "SyncWriteStream") return'
    end

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
  end
end
