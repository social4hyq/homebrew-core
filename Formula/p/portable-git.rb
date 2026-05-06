require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableGit < PortableFormula
  desc "Distributed revision control system"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.54.0.tar.xz"
  sha256 "f689162364c10de79ef89aa8dbf48731eb057e34edbbd20aca510ce0154681a3"
  license "GPL-2.0-only"
  head "https://github.com/git/git.git", branch: "master"

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/software/scm/git/"
    regex(/href=.*?git[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afc62eab12b28ff1307d0368d0acd11dfc3e76231dd4565f3cb9b7458e0f2347"
  end

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/portable-git/0001-let-git-portable.patch"
    sha256 "6eb03c44ec8eae2eeee0cea41175f909fe4eff1edfa0e7f840e896ba68c1c25e"
  end

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/git/0001-disable-pthread-setcancelstate.patch"
    sha256 "6fa9c77a7e753939b5fdc31df0c66cf0f49541f128fb12a51b38ef3f76c876aa"
  end

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/git/0002-skip-ownership-check.patch"
    sha256 "e8558f417bce4cb8515e5f26fba2a268c8e0bdee8675cfe7cec598052bc1675d"
  end

  depends_on "portable-openssl" => :build
  depends_on "portable-zlib" => :build
  depends_on "portable-expat" => :build
  depends_on "portable-libiconv" => :build
  depends_on "portable-pcre2" => :build
  depends_on "portable-curl" => :build
  depends_on "autoconf" => :build

  def install
    ENV.append "CFLAGS", "-DRUNTIME_PREFIX"
    ENV["NO_GETTEXT"] = "1"
    ENV["LIBS"] = "-lcurl -lssl -lcrypto -lz"

    args = %W[
      --prefix=#{prefix}
      --with-expat=#{Formula["portable-expat"].opt_prefix}
      --with-libpcre2=#{Formula["portable-pcre2"].opt_prefix}
      --with-openssl=#{Formula["portable-openssl"].opt_prefix}
      --with-iconv=#{Formula["portable-libiconv"].opt_prefix}
      --with-curl=#{Formula["portable-curl"].opt_prefix}
      --with-zlib=#{Formula["portable-zlib"].opt_prefix}
      --with-editor=false
      --with-pager=more
      --with-tcltk=no
    ]

    system "make", "configure"
    system "./configure", *args
    system "make", "install", "RUNTIME_PREFIX=1", "NO_GETTEXT=1", "INSTALL_SYMLINKS=1"
  end

  test do
    system bin/"git", "init"
    %w[haunted house].each { |f| touch testpath/f }
    system bin/"git", "add", "haunted", "house"
    system bin/"git", "config", "user.name", "'A U Thor'"
    system bin/"git", "config", "user.email", "author@example.com"
    system bin/"git", "commit", "-a", "-m", "Initial Commit"
    assert_equal "haunted\nhouse", shell_output("#{bin}/git ls-files").strip
  end
end
