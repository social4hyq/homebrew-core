class Ctpv < Formula
  desc "Image previews for lf file manager"
  homepage "https://github.com/NikitaIvanovV/ctpv"
  url "https://github.com/NikitaIvanovV/ctpv/archive/refs/tags/v1.1.tar.gz"
  sha256 "29e458fbc822e960f052b47a1550cb149c28768615cc2dddf21facc5c86f7463"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b331ce82cdf0733c7235cddeb7162e8ea99dc59d0475fe9c983b41bd849264c3"
  end

  depends_on "libmagic"
  depends_on "openssl@3"

  fails_with :clang do
    build 1300
    cause "Requires Clang 14 or later"
  end

  def install
    # Workaround for arm64 linux, issue ref: https://github.com/NikitaIvanovV/ctpv/issues/101
    ENV.append_to_cflags "-fsigned-char" if OS.linux? && Hardware::CPU.arm?

    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    file = test_fixtures("test.diff")
    output = shell_output("#{bin}/ctpv #{file}")
    assert_match shell_output("cat #{file}"), output
  end
end
