class MkConfigure < Formula
  desc "Lightweight replacement for GNU autotools"
  homepage "https://github.com/cheusov/mk-configure"
  url "https://downloads.sourceforge.net/project/mk-configure/mk-configure/mk-configure-0.40.0/mk-configure-0.40.0.tar.gz"
  sha256 "2a422f78752d25f37800cdfe5e96f1d081066837feefb8c8109db4e1daf51d4d"
  license all_of: ["BSD-2-Clause", "BSD-3-Clause", "MIT", "MIT-CMU"]

  livecheck do
    url :stable
    regex(%r{url=.*?/mk-configure[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b34f65275e277f327d92092b405714728239a61d70ea8c5652d2bccf2863d9b"
  end

  depends_on "bmake"
  depends_on "makedepend"

  def install
    ENV["PREFIX"] = prefix
    ENV["MANDIR"] = man

    system "bmake", "all"
    system "bmake", "install"
    doc.install "presentation/presentation.pdf"
  end

  test do
    system bin/"mkcmake", "-V", "MAKE_VERSION", "-f", File::NULL
  end
end
