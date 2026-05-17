class Wemux < Formula
  desc "Enhances tmux's to provide multiuser terminal multiplexing"
  homepage "https://github.com/zolrath/wemux"
  url "https://github.com/zolrath/wemux/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "8de6607df116b86e2efddfe3740fc5eef002674e551668e5dde23e21b469b06c"
  license "MIT"
  head "https://github.com/zolrath/wemux.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6bf9eedc50eff5efbf22cd3922af3dded0d1de12167559115bf80f0e75c6afd"
  end

  depends_on "tmux"

  def install
    inreplace "wemux", "/usr/local/etc", etc
    bin.install "wemux"
    man1.install "man/wemux.1"
    etc.install "wemux.conf.example" => "wemux.conf"
  end

  def post_install
    inreplace etc/"wemux.conf", "change_this", ENV["USER"], audit_result: false
  end

  def caveats
    <<~EOS
      Your current user account has been automatically added as a wemux host.

      To give a user the ability to host wemux sessions add them to the
      host_list array in:
        #{etc}/wemux.conf

      Either edit the file in your text editor of choice or run `wemux conf` to
      open the file in your $EDITOR.
    EOS
  end

  test do
    system bin/"wemux", "help"
  end
end
