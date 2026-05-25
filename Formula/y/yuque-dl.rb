class YuqueDl < Formula
  desc "Knowledge base downloader for Yuque"
  homepage "https://github.com/gxr404/yuque-dl"
  url "https://registry.npmjs.org/yuque-dl/-/yuque-dl-1.0.84.tgz"
  sha256 "c7868454ed6ff486ee1ef5261003504dd304174ef4914bf787bc3f70acfcd1f9"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f213583b752f7d4d6cc7563c44e4e570e030715d3760a5f719a77d36844c4b45"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/yuque-dl/node_modules"
    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yuque-dl --version")

    assert_match "Please enter a valid URL", shell_output("#{bin}/yuque-dl test 2>&1", 1)
  end
end
