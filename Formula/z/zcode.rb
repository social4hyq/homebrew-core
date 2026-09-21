class Zcode < Formula
  require "yaml"

  desc "AI coding workbench: terminal agent with TUI and web IDE"
  homepage "https://github.com/zai-org/ZCode"
  # Upstream releases without git tags; version comes from package.json.
  url "https://github.com/zai-org/ZCode.git",
      revision: "872ad960de7ec172591f7e1952f7849229f94521"
  version "3.14.0"
  license "Apache-2.0"
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

  depends_on "bun"
  depends_on "node" # build tooling plus the ZCODE_RUNTIME=node fallback

  # The repo pins pnpm 10.33.2 (packageManager); brew's pnpm 12 would fetch
  # an @pnpm/exe build that does not exist for openharmony.
  resource "pnpm" do
    url "https://registry.npmjs.org/pnpm/-/pnpm-10.33.2.tgz"
    sha256 "7a7bcf13d7f6ceb3946c03978373d99be9fde1cafc3000bdfed4c4f791167610"
  end

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

    resource("pnpm").stage buildpath/"pnpm-pkg"
    (buildpath/"pnpm-bin").mkpath
    (buildpath/"pnpm-bin/pnpm").write <<~SH
      #!/bin/sh
      exec node "#{buildpath}/pnpm-pkg/bin/pnpm.cjs" "$@"
    SH
    chmod 0755, buildpath/"pnpm-bin/pnpm"
    ENV.prepend_path "PATH", buildpath/"pnpm-bin"
    ENV["ELECTRON_SKIP_BINARY_DOWNLOAD"] = "1"

    # Overrides re-resolve the lockfile; CI would freeze the stale one.
    system "pnpm", "install", "--no-frozen-lockfile"

    # The openharmony esbuild shim forwards fs.writeSync back into
    # process.stderr, which recurses when stderr is a file (build logs).
    esbuild_shim = buildpath/"node_modules/@esbuild/openharmony-arm64/bin/esbuild"
    if esbuild_shim.exist? && esbuild_shim.read.exclude?("SyncWriteStream")
      inreplace esbuild_shim,
                "  if (fd === process.stdout.fd) return process.stdout.write(buf), buf.length;\n  " \
                "if (fd === process.stderr.fd) return process.stderr.write(buf), buf.length;",
                "  if (fd === process.stdout.fd && process.stdout.constructor.name !== \"SyncWriteStream\") " \
                "return process.stdout.write(buf), buf.length;\n  " \
                "if (fd === process.stderr.fd && process.stderr.constructor.name !== \"SyncWriteStream\") " \
                "return process.stderr.write(buf), buf.length;"
    end

    # turbo ships no openharmony binary; run the build steps in order.
    system "pnpm", "--filter", "@zcode/cli...", "--filter", "!@zcode/cli", "build"
    cd "apps/zcode-cli/packages/cli" do
      system "node", "scripts/build.mjs"
    end
    system "pnpm", "--filter", "@zcode/server", "build"
    system "pnpm", "--filter", "@zcode/web", "build"
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
    (bin/"zcode").write <<~SH
      #!/bin/sh
      case "${ZCODE_RUNTIME:-bun}" in
        node) exec "#{formula_opt_bin("node")}/node" "#{libexec}/zcode/bin/zcode.mjs" "$@" ;;
        *)    exec "#{formula_opt_bin("bun")}/bun" "#{libexec}/zcode/bin/zcode.mjs" "$@" ;;
      esac
    SH
    chmod 0755, bin/"zcode"
  end

  def caveats
    <<~EOS
      zcode runs on the bun runtime by default (full interactive TUI).
      Set ZCODE_RUNTIME=node to switch to Node.js instead: the web IDE's
      embedded terminal works there, but the TUI cannot start because
      HarmonyOS denies libffi the executable anonymous memory its
      JS-to-native callbacks need.

      Browser automation (playwright-core) has no openharmony build in its
      upstream loader, so browser-use skills are unavailable on this
      platform regardless of runtime. CUA screen capture is disabled
      (koffi does not build for OHOS arm64).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zcode --version")
    assert_match "Usage:", shell_output("#{bin}/zcode --help")
    assert_match version.to_s, shell_output("ZCODE_RUNTIME=node #{bin}/zcode --version")
  end
end
