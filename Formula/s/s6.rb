class S6 < Formula
  desc "Small & secure supervision software suite"
  homepage "https://skarnet.org/software/s6/"
  url "https://skarnet.org/software/s6/s6-2.14.0.1.tar.gz"
  sha256 "c25afe817cbc3f594efc5050351f8b9101ba78616d0ce915658f370e7ee2e258"
  license "ISC"
  head "git://git.skarnet.org/s6.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41e0388759021e10353387725bf8ad59d56eff9fd2d2169471bd39a795170aba"
  end

  depends_on "pkgconf" => :build
  depends_on "execline"
  depends_on "skalibs"

  def install
    args = %W[
      --disable-silent-rules
      --enable-shared
      --enable-pkgconfig
      --with-pkgconfig=#{Formula["pkgconf"].opt_bin}/pkg-config
      --with-sysdeps=#{Formula["skalibs"].opt_lib}/skalibs/sysdeps
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"log").mkpath
    pipe_output("#{bin}/s6-log #{testpath}/log", "Test input\n", 0)
    assert_equal "Test input\n", File.read(testpath/"log/current")
  end
end
