class Ired < Formula
  desc "Minimalistic hexadecimal editor designed to be used in scripts"
  homepage "https://github.com/radare/ired"
  url "https://github.com/radare/ired/archive/refs/tags/0.6.tar.gz"
  sha256 "c15d37b96b1a25c44435d824bd7ef1f9aea9dc191be14c78b689d3156312d58a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c33955ba456469079e495073d417d2477ff62e163f1863dd7af627eb9d768ae"
  end

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    input = <<~EOS
      w"hello wurld"
      s+7
      r-4
      w"orld"
      q
    EOS
    pipe_output("#{bin}/ired test.text", input)
    assert_equal "hello world", (testpath/"test.text").read.chomp
  end
end
