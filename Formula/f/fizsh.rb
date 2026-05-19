class Fizsh < Formula
  desc "Fish-like front end for ZSH"
  homepage "https://github.com/zsh-users/fizsh"
  url "https://downloads.sourceforge.net/project/fizsh/fizsh-1.0.9.tar.gz"
  sha256 "dbbbe03101f82e62f1dfe1f8af7cde23bc043833679bc74601a0a3d58a117b07"
  license "BSD-3-Clause"
  head "https://github.com/zsh-users/fizsh.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{url=.*?/fizsh[._-]v?(\d+(?:\.\d+)+(?:-\d+)?)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7b1a9f3a64646eb5cd689f0d7998acdf9a2c761774d8038e1546a9ea50c2a041"
  end

  depends_on "zsh"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_equal "hello", shell_output("#{bin}/fizsh -c \"echo hello\"").strip
  end
end
