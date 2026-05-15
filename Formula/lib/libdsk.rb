class Libdsk < Formula
  desc "Library for accessing discs and disc image files"
  homepage "https://www.seasip.info/Unix/LibDsk/"
  url "https://www.seasip.info/Unix/LibDsk/libdsk-1.4.2.tar.gz"
  sha256 "71eda9d0e33ab580cea1bb507467877d33d887cea6ec042b8d969004db89901a"
  license "LGPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/Stable version.*?href=.*?libdsk[._-]v?(\d+(?:\.\d+)+)\.t/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0345a5fcbba6da278a0dfb09db57db4abdd1bbbcca39df171923522a58c3abc6"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    # Avoid lyx dependency
    inreplace "Makefile.in", "SUBDIRS = . include lib tools man doc",
                             "SUBDIRS = . include lib tools man"

    args = []
    if OS.linux?
      # Help old config scripts identify arm64 linux
      args << "--build=aarch64-unknown-linux-gnu" if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # Workaround for undefined reference to `major'. Remove in the next release
      ENV.append "CFLAGS", "-include sys/sysmacros.h"
      odie "Remove sys/sysmacros.h workaround!" if version >= "1.5"
    end

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "check"
    system "make", "install"
    doc.install Dir["doc/*.{html,pdf,sample,txt}"]
  end

  test do
    assert_equal "#{name} version #{version}\n", shell_output("#{bin}/dskutil --version")
  end
end
