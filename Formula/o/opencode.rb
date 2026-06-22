class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64"
  homepage "https://github.com/anomalyco/opencode"
  license "MIT"
  stable do
    url "https://gh-proxy.com/https://github.com/anomalyco/opencode.git",
        revision: "11e47f91496005aab4d7c5a2d0a7da5d2651b4ac"
    version "1.17.8"
  end

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/opencode-v1.17.8"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a706c98a08a04cfb16f1e6fb5ece1bcf08d280254373c0802f3fd0ea29e70fc0"
  end

  patch :p1 do; file "Patches/opencode/build-ohos-target.patch"; end
  patch :p1 do; file "Patches/opencode/project-global-worktree.patch"; end
  patch :p1 do; file "Patches/opencode/esbuild-rolldown-bump.patch"; end
  patch :p1 do; file "Patches/opencode/vite-rolldown-catalog.patch"; end
  depends_on "bun"
  depends_on "ohos-sdk"
  depends_on "node"
  depends_on "bun-pty"
  depends_on "lightningcss"
  depends_on "tailwindcss-oxide"
  depends_on "llvm@21"
  depends_on "python@3.14" => :build

  def install
    ENV["PYTHON"] = Formula["python@3.14"].opt_bin/"python3"
    ENV["npm_config_nodedir"] = Formula["node"].opt_prefix.to_s
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    # 持久 bun 缓存（buildpath 每次会清空，导致网络失败的包每次重下；放 HOMEBREW_CACHE）
    ENV["BUN_INSTALL_CACHE"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    system "bun", "install", "--ignore-scripts"

    # build.ts 默认会跑 bun install --os=* --cpu=* 拉全平台 native 变体，但它依赖
    # Bun.$ → 在 OHOS 上 sh 无法 exec PATH 中的 bun（EPERM），所以我们传 --skip-install
    # 跳过 build.ts 内部的版本，改在这里直接调用，避开破损的 $ 路径。
    cd "packages/opencode" do
      system "bun", "install", "--os=*", "--cpu=*", "@opentui/core@0.3.4"
      system "bun", "install", "--os=*", "--cpu=*", "@parcel/watcher@2.5.1"
      system "bun", "install", "--os=*", "--cpu=*", "@ff-labs/fff-bun@0.9.4"
    end

    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    objcopy   = Formula["llvm@21"].opt_bin/"llvm-objcopy"

    deploy_native = lambda do |src, dest|
      cp src, dest
      system sign_tool, "sign", "-selfSign", "1", "-inFile", dest, "-outFile", dest
      chmod 0755, dest
    end

    Dir.glob("node_modules/**/*.{so,node}", File::FNM_DOTMATCH).each do |f|
      next unless File.file?(f) && !File.symlink?(f)
      next unless File.binread(f, 4) == "\x7fELF"
      system sign_tool, "sign", "-selfSign", "1", "-inFile", f, "-outFile", f
      chmod 0755, f
    end

    pty_so = Formula["bun-pty"].opt_lib/"librust_pty.so"
    Dir.glob("node_modules/**/bun-pty/rust-pty/target/release", File::FNM_DOTMATCH).each do |d|
      %w[librust_pty_arm64_musl.so librust_pty_arm64.so librust_pty.so].each do |n|
        deploy_native.call(pty_so, "#{d}/#{n}")
      end
    end

    lcss_so = Formula["lightningcss"].opt_lib/"liblightningcss_node.so"
    Dir.glob("node_modules/**/lightningcss", File::FNM_DOTMATCH).each do |d|
      next unless File.directory?(d)
      %w[lightningcss.linux-arm64-ohos.node
         lightningcss.openharmony-arm64.node
         lightningcss.linux-arm64-musl.node].each do |n|
        deploy_native.call(lcss_so, "#{d}/#{n}")
      end
      loader = "#{d}/node/index.js"
      next unless File.exist?(loader)
      content = File.read(loader)
      next if content.include?("process.platform === 'openharmony'")
      File.write(loader, content.sub(
        /^let parts = \[process\.platform, process\.arch\];\nif \(process\.platform === 'linux'\) \{/,
        "let parts = [process.platform, process.arch];\n" \
        "if (process.platform === 'openharmony') {\n" \
        "  parts = ['linux', process.arch, 'ohos'];\n" \
        "} else if (process.platform === 'linux') {",
      ))
    end

    tw_so = Formula["tailwindcss-oxide"].opt_lib/"libtailwind_oxide.so"
    Dir.glob("node_modules/**/@tailwindcss/oxide", File::FNM_DOTMATCH).each do |d|
      deploy_native.call(tw_so, "#{d}/tailwindcss-oxide.linux-arm64-musl.node")
      loader = "#{d}/index.js"
      next unless File.exist?(loader)
      content = File.read(loader)
      next if content.include?("process.platform === 'openharmony'")
      # isMusl(): treat openharmony as musl
      content = content.sub(
        "if (process.platform === 'linux') {\n    musl = isMuslFromFilesystem()",
        "if (process.platform === 'linux' || process.platform === 'openharmony') {\n" \
        "    if (process.platform === 'openharmony') return true\n" \
        "    musl = isMuslFromFilesystem()",
      )
      # requireNative(): match openharmony alongside linux
      content = content.sub(
        "} else if (process.platform === 'linux') {",
        "} else if (process.platform === 'linux' || process.platform === 'openharmony') {",
      )
      File.write(loader, content)
    end

    # Bun runtime symlink: Bun.build({compile: {target: "bun-linux-arm64-musl"}}) 期望本地 bun
    bun_runtime = buildpath/"packages/opencode/bun-linux-aarch64-musl-v1.4.0"
    ln_sf Formula["bun"].opt_bin/"bun", bun_runtime

    cd "packages/opencode" do
      version = JSON.parse(File.read("package.json"))["version"]
      ENV["OPENCODE_VERSION"] = version
    end

    # 1) 预编译 Web UI（vite→rolldown-vite）
    system "bun", "run", "--cwd", "packages/app", "build"

    # 2) bun compile + 嵌入 Web UI（SKIP_VITE_BUILD=1 跳过 build.ts 内的二次 vite 调用）
    cd "packages/opencode" do
      ENV["SKIP_VITE_BUILD"] = "1"
      system "bun", "run", "script/build.ts", "--single", "--skip-install"
    end

    # 3) strip 内嵌 .codesign 段后用 binary-sign-tool 重签
    out = "packages/opencode/dist/opencode-openharmony-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)
    unsigned = "#{out}.unsigned"
    stripped = "#{out}.stripped"
    mv out, unsigned
    system objcopy, "--remove-section", ".codesign", unsigned, stripped
    system sign_tool, "sign", "-selfSign", "1", "-inFile", stripped, "-outFile", out
    chmod 0755, out
    rm unsigned
    rm stripped
    bin.install out => "opencode"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
