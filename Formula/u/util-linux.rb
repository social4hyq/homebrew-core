class UtilLinux < Formula
  desc "Collection of Linux utilities"
  homepage "https://github.com/util-linux/util-linux"
  url "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.42/util-linux-2.42.tar.xz"
  sha256 "3452b260bbaa775d6e749ac3bb22111785003fc1f444970025c8da26dfa758e9"
  license all_of: [
    "BSD-3-Clause",
    "BSD-4-Clause-UC",
    "GPL-2.0-only",
    "GPL-2.0-or-later",
    "GPL-3.0-or-later",
    "LGPL-2.1-or-later",
    :public_domain,
  ]
  revision 2
  compatibility_version 1

  # The directory listing where the `stable` archive is found uses major/minor
  # version directories, where it's necessary to check inside a directory to
  # find the full version. The newest directory can contain unstable versions,
  # so it could require more than two requests to identify the newest stable
  # version. With this in mind, we simply check the Git tags as a best effort.
  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "285a2aa2714f5959a7cc0645ed053132d51ccc5bba96c1693bc1805c34e673c4"
  end

  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "autoconf" => :build
  depends_on "gettext"

  # Fix macOS builds
  # https://github.com/util-linux/util-linux/pull/4173
  patch do
    url "https://github.com/util-linux/util-linux/commit/d22edc2f100eb8dd83d3515758565cb73b0d2eed.patch?full_index=1"
    sha256 "2fb01154faa3fd8b0fce27eb88049ed9c8f839e706e412399c19c087f7f3b5e1"
  end

  def install
    inreplace "lib/shells.c", '#include <unistd.h>', "#include <unistd.h>\nextern char *getusershell(void);\nextern void setusershell(void);\nextern void endusershell(void);"

    # Bypass gtk-doc dependency
    ENV["GTKDOCIZE"] = "/bin/true"

    system "autoreconf", "--force", "--install", "--verbose"

    # Due to compilation failures in too many programs,
    # build artifacts are specified via a whitelist only.

    uuid_args = %W[
      --disable-silent-rules
      --disable-liblastlog2
      --disable-all-programs
      --enable-libuuid
      --without-python
      --without-systemd
      --without-udev
    ]
    system "./configure", *std_configure_args, *uuid_args
    system "make"
    system "make", "install"

    system "make", "distclean"

    getopt_args = %W[
      --disable-silent-rules
      --disable-liblastlog2
      --enable-getopt
      --without-python
      --without-systemd
      --without-udev
    ]
    system "./configure", *std_configure_args, *getopt_args
    system "make", "getopt"
    bin.install "getopt"
  end

  test do
    system bin/"getopt", "--help"
  end
end
