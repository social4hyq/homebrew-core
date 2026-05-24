class Unrtf < Formula
  desc "RTF to other formats converter"
  homepage "https://www.gnu.org/software/unrtf/"
  url "https://ftpmirror.gnu.org/gnu/unrtf/unrtf-0.21.10.tar.gz"
  mirror "https://ftp.gnu.org/gnu/unrtf/unrtf-0.21.10.tar.gz"
  sha256 "b49f20211fa69fff97d42d6e782a62d7e2da670b064951f14bbff968c93734ae"
  license "GPL-3.0-or-later"
  head "https://hg.savannah.gnu.org/hgweb/unrtf/", using: :hg

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d690a0bdfed5b640f02a3e9019dfc84cb6562ae6a96625092645654494690f76"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    system "./bootstrap"
    args = %W[--prefix=#{prefix}]
    args << "LIBS=-liconv" if OS.mac?
    system "./configure", *args
    system "make", "install"
  end

  test do
    (testpath/"test.rtf").write <<~'RTF'
      {\rtf1\ansi
      {\b hello} world
      }
    RTF
    expected = <<~HTML
      <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
      <html>
      <head>
      <meta http-equiv="content-type" content="text/html; charset=utf-8">
      <!-- Translation from RTF performed by UnRTF, version #{version} -->
      </head>
      <body><b>hello</b> world</body>
      </html>
    HTML
    assert_equal expected, shell_output("#{bin}/unrtf --html test.rtf")
  end
end
