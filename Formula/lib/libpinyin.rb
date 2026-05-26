class Libpinyin < Formula
  desc "Library to deal with pinyin"
  homepage "https://github.com/libpinyin/libpinyin"
  license "GPL-3.0-or-later"

  stable do
    url "https://github.com/libpinyin/libpinyin/archive/refs/tags/2.10.3.tar.gz"
    sha256 "a49286721fb2b0234d86c095db9226246b0aa4a0bb6a885d0902da2743c56476"

    on_macos do
      depends_on "berkeley-db"
    end

    on_linux do
      # We use the older Berkeley DB as it is already an indirect dependency
      # (glib -> python@3.y -> berkeley-db@5) and gets linked by default
      depends_on "berkeley-db@5"
    end
  end

  # Tags with a 90+ patch are unstable (e.g., the 2.9.91 tag is marked as
  # pre-release on GitHub) and this regex should only match the stable versions.
  livecheck do
    url :stable
    regex(/^v?(\d+\.\d+\.(?:\d|[1-8]\d+)(?:\.\d+)*)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ddf0df2493976b4eb0ad6f74d4630f5b0e9b9f48b0861a4d5ccaf3f10a37b3c"
  end

  head do
    url "https://github.com/libpinyin/libpinyin.git", branch: "main"

    depends_on "tkrzw"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  # The language model file is independently maintained by the project owner.
  # To update this resource block, the URL can be found in data/Makefile.am.
  resource "model" do
    url "https://downloads.sourceforge.net/libpinyin/models/model20.text.tar.gz"
    sha256 "59c68e89d43ff85f5a309489499cbcde282d2b04bd91888734884b7defcb1155"
  end

  def install
    resource("model").stage buildpath/"data"

    args = %w[
      --enable-libzhuyin=yes
      --disable-silent-rules
    ]

    # Berkeley DB seems to be low/questionable maintenance while Kyoto Cabinet was succeeded by Tkrzw
    if build.head?
      args << "--with-dbm=Tkrzw"
      ENV.append "CXXFLAGS", "-std=c++17"
    elsif version >= "2.12"
      odie "Switch DBM to Tkrzw! Also switch to release tarball and use ./configure in stable."
    end

    system "./autogen.sh", *args, *std_configure_args
    system "make", "install"
  end

  def caveats
    "The formula will switch DBM to Tkrzw in version 2.12 which may impact user data."
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <pinyin.h>

      int main()
      {
          pinyin_context_t * context = pinyin_init (LIBPINYIN_DATADIR, "");

          if (context == NULL)
              return 1;

          pinyin_instance_t * instance = pinyin_alloc_instance (context);

          if (instance == NULL)
              return 1;

          pinyin_free_instance (instance);

          pinyin_fini (context);

          return 0;
      }
    CPP

    flags = shell_output("pkgconf --cflags --libs libpinyin").chomp.split
    system ENV.cxx, "test.cc", "-o", "test", "-DLIBPINYIN_DATADIR=\"#{lib}/libpinyin/data/\"", *flags
    touch "user.conf"
    system "./test"
  end
end
