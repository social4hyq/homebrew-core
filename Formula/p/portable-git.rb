require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableGit < PortableFormula
  desc "Distributed revision control system"
  homepage "https://git-scm.com"
  url "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.55.0.tar.xz"
  sha256 "457fdb04dc8728e007d4688695e6912e6f680727920f2a40bf11eacc17505357"
  license "GPL-2.0-only"
  revision 1
  head "https://github.com/git/git.git", branch: "master"

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/software/scm/git/"
    regex(/href=.*?git[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  no_autobump! because: "this is a critical package so an auto bump might break Homebrew usability."

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "131f66b2171b688a958e7317c593e38d851386aef659abb1314bb4c6f198bac9"
  end

  patch do
    file "Patches/portable-git/0001-disable-pthread-setcancelstate.patch"
  end

  patch do
    file "Patches/portable-git/0002-skip-ownership-check.patch"
  end

  patch do
    file "Patches/portable-git/0003-let-git-portable.patch"
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
    system "./configure", "ac_cv_header_libintl_h=no", *args
    system "make", "install", "RUNTIME_PREFIX=1", "INSTALL_SYMLINKS=1", "NO_RUST=1"
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
