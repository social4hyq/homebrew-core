class Bar < Formula
  desc "Provide progress bars for shell scripts"
  homepage "http://www.theiling.de/projects/bar.html"
  url "http://www.theiling.de/downloads/bar-1.4-src.tar.bz2"
  sha256 "8034c405b6aa0d474c75ef9356cde1672b8b81834edc7bd94fc91e8ae097033e"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d83753e0cddaa61e580c7c8cbd017fe8e5d407b55fb0df9cb9d1b76a6c7d365a"
  end

  deprecate! date: "2026-01-05", because: "is not available via HTTPS"

  def install
    bin.install "bar"
  end

  test do
    (testpath/"test1").write "pumpkin"
    (testpath/"test2").write "latte"
    assert_match "latte", shell_output("#{bin}/bar test1 test2")
  end
end
