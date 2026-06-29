class YuqueDl < Formula
  desc "Knowledge base downloader for Yuque"
  homepage "https://github.com/gxr404/yuque-dl"
  url "https://registry.npmjs.org/yuque-dl/-/yuque-dl-1.0.85.tgz"
  sha256 "5730d4745f908781305beb1ad86e14fd00865e4b4f5a414c695112b6871ea410"
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
