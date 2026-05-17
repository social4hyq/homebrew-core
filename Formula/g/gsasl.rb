class Gsasl < Formula
  desc "SASL library command-line interface"
  homepage "https://www.gnu.org/software/gsasl/"
  url "https://ftpmirror.gnu.org/gnu/gsasl/gsasl-2.2.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gsasl/gsasl-2.2.3.tar.gz"
  sha256 "fee36c66ac12d32d3bf29a7b35ad8f444b7996fe369b9da5d36fd6ae649c68eb"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "654b7cfbaeaec4882ef7d82cd3936ef486eb9d815d9c30f40f374e941261c779"
  end

  depends_on "libgcrypt"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "./configure", "--with-gssapi-impl=mit", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gsasl --version")
  end
end
