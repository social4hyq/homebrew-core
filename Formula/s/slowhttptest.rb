class Slowhttptest < Formula
  desc "Simulates application layer denial of service attacks"
  homepage "https://github.com/shekyan/slowhttptest"
  url "https://github.com/shekyan/slowhttptest/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "a3910b9b844e05ee55838aa17beddc6aa9d6c5c0012eab647a21cc9ccd6c8749"
  license "Apache-2.0"
  head "https://github.com/shekyan/slowhttptest.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3cd4d4b1f247aea8055ae8e455a365fd1576e6ea1aa2d983534d5fa2ed22386c"
  end

  depends_on "openssl@4"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"slowhttptest", "-u", "https://google.com",
                                  "-p", "1", "-r", "1", "-l", "1", "-i", "1"

    assert_match version.to_s, shell_output("#{bin}/slowhttptest -h", 1)
  end
end
