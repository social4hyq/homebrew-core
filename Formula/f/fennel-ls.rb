class FennelLs < Formula
  desc "Language Server for Fennel"
  homepage "https://git.sr.ht/~xerool/fennel-ls/"
  url "https://git.sr.ht/~xerool/fennel-ls/archive/0.2.4.tar.gz"
  sha256 "d50a48e2c65e84c87694cf7fd142ffcfc3a573567a1610a0b1accb97930ee2d5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "080ed913ef766f0c76502e2bbb4008d17c66eaa2c8280544f52b99328a0b5397"
  end

  depends_on "pandoc" => :build
  depends_on "lua"

  def install
    system "make"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fennel-ls --version")

    (testpath/"test.fnl").write <<~FENNEL
      { foo }
    FENNEL

    expected = "test.fnl:1:6: error: expected even number of values in table literal"
    assert_match expected, shell_output("#{bin}/fennel-ls --lint test.fnl 2>&1", 1)
  end
end
