class Surfraw < Formula
  desc "Shell Users' Revolutionary Front Rage Against the Web"
  homepage "https://gitlab.com/surfraw/Surfraw"
  url "https://ftp.openbsd.org/pub/OpenBSD/distfiles/surfraw-2.3.0.tar.gz"
  sha256 "ad0420583c8cdd84a31437e59536f8070f15ba4585598d82638b950e5c5c3625"
  license :public_domain

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "249fb0efd6a0f869362b4790a16852d7663802985bc562c36f2481c9bb98a992"
  end

  head do
    url "https://gitlab.com/surfraw/Surfraw.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--sysconfdir=#{etc}",
                          "--with-graphical-browser=open",
                          *std_configure_args
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/surfraw -p duckduckgo homebrew")
    assert_equal "https://duckduckgo.com/lite/?q=homebrew", output.chomp
  end
end
