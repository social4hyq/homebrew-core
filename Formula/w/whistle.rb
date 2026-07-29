class Whistle < Formula
  desc "HTTP, HTTP2, HTTPS, Websocket debugging proxy"
  homepage "https://github.com/avwo/whistle"
  url "https://registry.npmjs.org/whistle/-/whistle-2.10.7.tgz"
  sha256 "dac31bb30d6bbce1deb4bdf0d53f86f29bc43ab8641a9291c41794207647d4fb"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1a7d9e428eae9e51ff0925992a72a0c5e33f71fa2813fe3e11a6f1bcebe5ddd4"
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
