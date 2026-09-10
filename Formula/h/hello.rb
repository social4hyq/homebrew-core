class Hello < Formula
  desc "Program providing model for GNU coding standards and practices"
  homepage "https://www.gnu.org/software/hello/"
  url "https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
  sha256 "0d5f60154382fee10b114a1c34e785d8b1f492073ae2d3a6f7b147687b366aa0"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d87cac72d074ae8fcd7e99d751d7468a00654809438b819869b0ec08ad78535"
  end

  def install
    ENV.append "LDFLAGS", "-liconv" if OS.mac?

    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
  test do
    assert_equal "brew", shell_output("#{bin}/hello --greeting=brew").chomp
  end
end
