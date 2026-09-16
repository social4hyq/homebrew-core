class Whistle < Formula
  desc "HTTP, HTTP2, HTTPS, Websocket debugging proxy"
  homepage "https://github.com/avwo/whistle"
  url "https://registry.npmjs.org/whistle/-/whistle-2.10.10.tgz"
  sha256 "f04b0744547cffc03aa18efb56949db3bdbfc787466b7773246fd7d5aa347def"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "847603a76fa86c5509d2794b91c55019ee8716e33e5e619feb486fc0a9732922"
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
