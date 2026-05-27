class Ioping < Formula
  desc "Tool to monitor I/O latency in real time"
  homepage "https://github.com/koct9i/ioping"
  url "https://github.com/koct9i/ioping/archive/refs/tags/v1.3.tar.gz"
  sha256 "7aa48e70aaa766bc112dea57ebbe56700626871052380709df3a26f46766e8c8"
  license "GPL-3.0-or-later"
  head "https://github.com/koct9i/ioping.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c80accfcf0d4aeee25090a638d2db673f30874d09adfb9a90c1ec3189038764a"
  end

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"ioping", "-c", "1", testpath
  end
end
