class ClaudeCodeRouter < Formula
  desc "Tool to route Claude Code requests to different models and customize any request"
  homepage "https://github.com/musistudio/claude-code-router"
  url "https://registry.npmjs.org/@musistudio/claude-code-router/-/claude-code-router-3.0.22.tgz"
  sha256 "a6de50b2e69a8510159c31f903af495850220b1d61f67b409ef0f3a6e4eb3a48"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72966acee8593d225abaa9706366d63e9472e7ca9b5024f5040370872142ad65"
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
