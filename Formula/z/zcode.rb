class Zcode < Formula
  require "yaml"

  desc "AI coding workbench: terminal agent with TUI and web IDE"
  homepage "https://github.com/zai-org/ZCode"
  # Upstream releases without git tags; version comes from package.json.
  url "https://github.com/zai-org/ZCode.git",
      revision: "872ad960de7ec172591f7e1952f7849229f94521"
  version "3.14.0"
  license "Apache-2.0"
  revision 1
  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zcode-v3.14.0-r3"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6efca1713a026ad3f20acd1aed8f6657e0f243a2331e5e12f923d685ba61c5fa"
  end

  # pnpm 12 acts as itself with delegation to the packageManager pin
  # disabled (no openharmony @pnpm/exe exists).
  depends_on "node" => :build
  depends_on "pnpm" => :build
  depends_on "bun" # pnpm/tsc/vite toolchain

  %w[
    0001-ohos-sea-targets.patch
    0002-bun-node-sea-guards.patch
  ].each do |p|
    patch do
      file "Patches/zcode/#{p}"
    end
  end

  deny_network_access! :test

  def install
    # OHOS: community ports for platform binaries the toolchain cannot
    # build here, and build-time natives that publish openharmony packages.
    pkg_json = JSON.parse(File.read("package.json"))
    pkg_json["pnpm"]["overrides"] = {
      "node-pty"              => "npm:@ohos-ports/node-pty@1.1.0-beta.4",
      "@mbears/opentui-core"  => "npm:@ohos-npm-ports/opentui-core@0.5.8-2",
      "@mbears/opentui-react" => "npm:@opentui/react@0.5.8",
      "@opentui/core"         => "npm:@ohos-npm-ports/opentui-core@0.5.8-2",
      "esbuild"               => "0.28.2",
      "tailwindcss"           => "4.3.3",
      "@tailwindcss/vite"     => "4.3.3",
      "@tailwindcss/oxide"    => "npm:@ohos-npm-ports/tailwindcss-oxide@4.3.3-2",
      "lightningcss"          => "npm:@ohos-npm-ports/lightningcss@1.33.0-1",
    }.merge(pkg_json["pnpm"]["overrides"] || {})
    File.write("package.json", JSON.pretty_generate(pkg_json) << "\n")

    # koffi miscompiles x64 assembly on arm64 and only serves CUA capture.
    ws = YAML.safe_load_file("pnpm-workspace.yaml")
    ws["allowBuilds"].delete("koffi")
    File.write("pnpm-workspace.yaml", YAML.dump(ws))

    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV.prepend_path "PATH", formula_opt_bin("pnpm")
    ENV["ELECTRON_SKIP_BINARY_DOWNLOAD"] = "1"

    # Overrides re-resolve the lockfile; CI would freeze the stale one.
    system "pnpm", "install", "--no-frozen-lockfile"

    # The openharmony esbuild shim forwards fs.writeSync back into
    # process.stderr, which recurses when stderr is a file (build logs).
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
           "--base-url", "https://example.invalid/zcode/",
           "--out-dir", "dist/zcode"

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
