class Retire < Formula
  desc "Scanner detecting the use of JavaScript libraries with known vulnerabilities"
  homepage "https://retirejs.github.io/retire.js/"
  url "https://registry.npmjs.org/retire/-/retire-5.4.2.tgz"
  sha256 "49de4054a0dce5c990a3513fe5886c6c43bb0c236d199986090701e94f01e20e"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a93f41e4b223dd7c1753d9a22165dd64c0419a77c8d9a7d3e798f7a46c7ea980"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/retire --version")

    system "git", "clone", "https://github.com/appsecco/dvna.git"
    output = shell_output("#{bin}/retire --path dvna 2>&1", 13)
    assert_match(/jquery (\d+(?:\.\d+)+) has known vulnerabilities/, output)
  end
end
