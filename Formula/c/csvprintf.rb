class Csvprintf < Formula
  desc "Command-line utility for parsing CSV files"
  homepage "https://github.com/archiecobbs/csvprintf"
  url "https://github.com/archiecobbs/csvprintf/archive/refs/tags/1.3.4.tar.gz"
  sha256 "dff2ecf046bac822bc34fc8a452cecae3d22abeb85a9ac950dafdec4fedf0db2"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bd00abc88dd3ee139c536181c8893b5a88939da5c3169d8df239113428eb485d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libxslt"

  def install
    ENV.append "LDFLAGS", "-liconv" if OS.mac?

    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_equal "Fred Smith\n",
                 pipe_output("#{bin}/csvprintf -i '%2$s %1$s\n'", "Last,First\nSmith,Fred\n")
  end
end
