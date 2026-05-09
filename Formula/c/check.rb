class Check < Formula
  desc "C unit testing framework"
  homepage "https://libcheck.github.io/check/"
  url "https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz"
  sha256 "a8de4e0bacfb4d76dd1c618ded263523b53b85d92a146d8835eb1a52932fa20a"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5564f4f58ce24187a5e7fec77f8a443190863c85b4f268a6fbb3fd393b531d4a"
  end

  on_linux do
    depends_on "gawk"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.tc").write <<~EOS
      #test test1
      ck_assert_msg(1, "This should always pass");
    EOS

    system "#{bin/"checkmk"} test.tc > test.c"

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcheck", "-o", "test"
    system "./test"
  end
end
