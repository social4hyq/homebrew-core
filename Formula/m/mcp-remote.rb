class McpRemote < Formula
  desc "Remote proxy for Model Context Protocol with OAuth support"
  homepage "https://github.com/geelen/mcp-remote"
  url "https://registry.npmjs.org/mcp-remote/-/mcp-remote-0.3.3.tgz"
  sha256 "dd6c13944eef4cdf6d42119761b8b822a2e34dc8b9ba944f768aa3e920814286"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "626e19fc65406ca6222ce4ad75cf5e46e8e87fe244d2af2650a834d14f4a7076"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match "Using transport strategy: http-first",
      shell_output("#{bin}/mcp-remote https://mcp.example.com/mcp 2>&1", 1)
  end
end
