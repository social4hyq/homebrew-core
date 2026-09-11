class DeepseekHarness < Formula
  desc "Open-source agent harness developed by DeepSeek AI"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.5-rc.2.tgz"
  sha256 "f4c54839d69e82bf1c3a5a41a910c3ce1405cd9e9d97d753c0c04f406c7d7480"
  license "MIT"
  revision 2

  # The npm `next` dist-tag carries the rc line while `latest` lags behind it
  # (it still points at 0.1.5-rc.1). Read the published version list instead
  # and let livecheck pick the newest; alpha/beta builds are filtered out
  # because this formula tracks rc releases.
  livecheck do
    url "https://registry.npmjs.org/@deepseek-ai/dsh"
    strategy :json do |json|
      json["versions"].keys.grep_v(/-(?:alpha|beta|dev)\./i)
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9846e93917ef0ba207edd2a0d65029c69404c8ed4a5d93f965c74b5c5e831be"
  end

  depends_on "cmake" => :build
  depends_on "bash"
  depends_on "node"
  depends_on "ripgrep"

  def install
    require "json"

    # --min-release-age=0: Homebrew std_npm_args pins min-release-age=1 (1 day);
    # dsh sub-packages were published the same day, so the default age gate
    # rejects them (ETARGET). Freshly-released npm packages need this.
    system "npm", "install", *std_npm_args(ignore_scripts: true), "--min-release-age=0", "@img/sharp-wasm32"

    Dir.chdir(libexec/"lib/node_modules/@deepseek-ai/dsh") do
      # OpenHarmony toolchain: CMake cannot identify clang, so koffi's
      # CMAKE_CXX_STANDARD 20 is not injected (clang defaults to C++14);
      # force -std=c++20. Defer koffi's build until after this inreplace
      # (npm install would re-unpack and discard the inreplace below).
      #
      # This cwd is the dsh package root, so `npm install <pkg>` re-resolves
      # the whole project. dsh 0.1.2-rc.1's devDependencies reference
      # @deepseek-ai/dsh-experimental-* workspace packages that were never
      # published to the npm registry (E404); npm fetches devDependency
      # manifests even under --omit=dev, so drop the block outright: an
      # installed CLI never needs the source repo's dev tooling.
      manifest = JSON.parse(File.read("package.json"))
      manifest.delete("devDependencies")
      File.write("package.json", JSON.pretty_generate(manifest) + "\n")
      system "npm", "install", "--ignore-scripts"
      koffi_cmake = "node_modules/koffi/src/koffi/CMakeLists.txt"
      inreplace koffi_cmake, "set(CMAKE_CXX_STANDARD 20)",
                "set(CMAKE_CXX_STANDARD 20)\nset(CMAKE_CXX_FLAGS \"${CMAKE_CXX_FLAGS} -std=c++20\")"
      system "npm", "rebuild", "koffi", "node-pty"
    end

    # Patches target the scoped sub-packages that `npm install` materialises under
    # node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai. They cannot use the
    # declarative `patch do; file; end` form: that runs against the freshly-unpacked
    # source tree, before `npm install` creates these sub-package directories.
    patch_dir = File.expand_path("../../Patches/deepseek-harness", __dir__)
    dsh_modules = libexec/"lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai"
    Dir[File.join(patch_dir, "*.patch")].sort.each do |patch_file|
      system "patch", "-p1", "-d", dsh_modules, "-i", patch_file
    end

    (bin/"dsh").write <<~EOS
      #!/bin/sh
      export OPENSSL_armcap=0
      exec "#{formula_opt_bin("node")/"node"}" \\
        --expose-internals \\
        "#{libexec/"lib/node_modules/@deepseek-ai/dsh/lib/bin.js"}" \\
        "$@"
    EOS
    (bin/"dsh").chmod 0755
  end

  def caveats
    <<~EOS
      Run `dsh` command to use deepseek-harness:

        Web UI:   dsh web
        One-shot: dsh --profile headless "..."
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dsh --version")

    # Boot the Web UI on an OS-assigned port and verify the browser handshake
    # (303 + session cookie, then the app HTML) actually serves.
    log = testpath/"dsh-web.log"
    pid = spawn({}, "#{bin}/dsh", "web", "--no-open", "--port", "0", out: log.to_s, err: log.to_s)
    alive = lambda do
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
    end
    begin
      url = nil
      60.times do
        url = log.exist? ? log.read[/dsh web: (\S+)/, 1] : nil
        break if url
        raise "dsh web exited before serving" unless alive.call
        sleep 0.5
      end
      assert url, "dsh web did not print its URL within 30s"

      jar = testpath/"cookies.txt"
      html = testpath/"index.html"
      code = shell_output("curl -sL -c #{jar} -b #{jar} -o #{html} -w %{http_code} '#{url}'").strip
      assert_equal "200", code
      assert_match(/<!doctype html/i, html.read)
    ensure
      begin
        Process.kill("TERM", pid) if pid
      rescue Errno::ESRCH, Errno::EPERM
        # server already exited
      end
    end
  end
end
