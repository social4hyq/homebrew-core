class DeepseekHarness < Formula
  desc "Open-source agent harness developed by DeepSeek AI"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.1-rc.2.tgz"
  sha256 "47ec05f45ada5ab87779ae18a90456b5ebff5421dc0ff5c179677d65e1c16057"
  license "MIT"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "046f496a27148970d723f71a366652ce5c3881f3e3731fffaa1f7a9ceb8a5b2e"
  end

  depends_on "cmake" => :build
  depends_on "bash"
  depends_on "node"
  depends_on "ripgrep"

  def install
    # --min-release-age=0: Homebrew std_npm_args pins min-release-age=1 (1 day);
    # dsh 0.1.1-rc.2 sub-packages were published the same day, so the default
    # age gate rejects them (ETARGET). Freshly-released npm packages need this.
    system "npm", "install", *std_npm_args(ignore_scripts: true), "--min-release-age=0", "@img/sharp-wasm32"

    Dir.chdir(libexec/"lib/node_modules/@deepseek-ai/dsh") do
      # OpenHarmony toolchain: CMake cannot identify clang, so koffi's
      # CMAKE_CXX_STANDARD 20 is not injected (clang defaults to C++14) and
      # -fno-emulated-tls breaks the OpenHarmony lld. Force both flags, and
      # defer koffi's build until after patching (npm install would re-unpack
      # and discard the inreplace below).
      system "npm", "install", "koffi@^3.1.5", "--no-save", "--prefer-online", "--min-release-age=0", "--ignore-scripts"
      koffi_cmake = "node_modules/koffi/src/koffi/CMakeLists.txt"
      inreplace koffi_cmake, "set(CMAKE_CXX_STANDARD 20)",
                "set(CMAKE_CXX_STANDARD 20)\nset(CMAKE_CXX_FLAGS \"${CMAKE_CXX_FLAGS} -std=c++20 -femulated-tls\")"
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
  end
end
