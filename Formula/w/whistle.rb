class Whistle < Formula
  desc "HTTP, HTTP2, HTTPS, Websocket debugging proxy"
  homepage "https://github.com/avwo/whistle"
  url "https://registry.npmjs.org/whistle/-/whistle-2.10.5.tgz"
  sha256 "fa482caeea9a4c63379fb2d190713ee11d105004fd8b853cc832150d86291f4a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d9455a15b537cd1bbd53a70d96169346fa8e61d9347eea50df54a9dadf979ec7"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"package.json").write('{"name": "test"}')
    system bin/"whistle", "start"
    system bin/"whistle", "stop"
  end
end
