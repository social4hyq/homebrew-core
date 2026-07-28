class YuqueDl < Formula
  desc "Knowledge base downloader for Yuque"
  homepage "https://github.com/gxr404/yuque-dl"
  url "https://registry.npmjs.org/yuque-dl/-/yuque-dl-1.0.86.tgz"
  sha256 "930933a0c719613e26a8015d26b6cbfcd4ba314392929939c05b6ac635980177"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7f9b1c72da4609adf8d43ffa94b91765ae2ef62727cf5abd3abeae8647062ed"
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
