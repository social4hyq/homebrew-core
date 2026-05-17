class Bogofilter < Formula
  desc "Mail filter via statistical analysis"
  homepage "https://bogofilter.sourceforge.io"
  url "https://downloads.sourceforge.net/project/bogofilter/bogofilter-stable/bogofilter-1.2.5.tar.xz"
  sha256 "3248a1373bff552c500834adbea4b6caee04224516ae581fb25a4c6a6dee89ea"
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later"]

  livecheck do
    url "https://sourceforge.net/projects/bogofilter/rss?path=/bogofilter-stable"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ba28411c935dae70aa9b5ddfd5d0e52d19159a6bfb61cc110fdcf1eeab0f1ac1"
  end

  uses_from_macos "sqlite"

  def install
    system "./configure", "--disable-silent-rules",
                          "--with-database=sqlite3",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"bogofilter", "--version"
  end
end
