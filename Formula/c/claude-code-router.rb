class ClaudeCodeRouter < Formula
  desc "Tool to route Claude Code requests to different models and customize any request"
  homepage "https://github.com/musistudio/claude-code-router"
  url "https://registry.npmjs.org/@musistudio/claude-code-router/-/claude-code-router-3.0.17.tgz"
  sha256 "0575f11ad5fe62164143e7f4bae7afdf73c2f641f81e9bd718e56b30a8a04cb8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25ebece77b824dbfe1048a29d416ecfa0ce0473c3fc47a661fbcb1ee15a0403c"
  end

  depends_on "node"

  patch do
    file "Patches/claude-code-router/0001-add-ohos-source_location.patch"
  end

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Rebuild better-sqlite3 native addon for OHOS.
    # OHOS Clang 15 libc++ lacks the C++20 <source_location> header that
    # Node.js v26 V8 headers require, so we provide a stub.
    better_sqlite3_dir = libexec/"lib/node_modules/@musistudio/claude-code-router/node_modules/better-sqlite3"
    if better_sqlite3_dir.exist?
      ohos_stub_include = buildpath/"ohos_stub/include"
      ohos_stub_include.mkpath
      cp buildpath/"source_location",
         ohos_stub_include/"source_location"

      cd better_sqlite3_dir do
        ENV.append "CXXFLAGS", "-I#{ohos_stub_include}"
        system "npx", "--yes", "node-gyp", "rebuild", "--release"
      end
    end
  end

  test do
    # ccr exits with code 1 when no models are configured, but the binary
    # should run successfully without the "Could not locate the bindings file"
    # error from better-sqlite3.
    assert_match "No available models",
                 shell_output("#{bin}/ccr version 2>&1", 1)
    assert_match "No available models",
                 shell_output("#{bin}/ccr status 2>&1", 1)
  end
end
