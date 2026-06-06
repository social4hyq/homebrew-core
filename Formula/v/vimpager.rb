class Vimpager < Formula
  desc "Use ViM as PAGER"
  homepage "https://github.com/rkitover/vimpager"
  url "https://github.com/rkitover/vimpager/archive/refs/tags/2.06.tar.gz"
  sha256 "cc616d0840a6f2501704eea70de222ab662421f34b2da307e11fb62aa70bda5d"
  license "BSD-2-Clause"
  head "https://github.com/rkitover/vimpager.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ddbfa79c116ad37761484db033fead2ac9c7209fa9f9f899718a0929314f35e"
  end

  depends_on "pandoc" => :build

  def install
    system "make", "install", "PREFIX=#{prefix}"
    system "make", "docs"
  end

  def caveats
    <<~EOS
      To use vimpager as your default pager, add `export PAGER=vimpager` to your
      shell configuration.
    EOS
  end

  test do
    (testpath/"test.txt").write <<~EOS
      This is test
    EOS

    assert_match(/This is test/, shell_output("#{bin}/vimcat test.txt"))
  end
end
