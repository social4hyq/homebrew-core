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
    sha256 cellar: :any_skip_relocation, arm64_ohos: "50b97c49d03426389d3cfebbf6240f39fec89b96fa8a4c6591fd9450d2bce472"
  end

  depends_on "gettext" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  # Fix macOS builds
  # https://github.com/util-linux/util-linux/pull/4173
  patch do
    url "https://github.com/util-linux/util-linux/commit/d22edc2f100eb8dd83d3515758565cb73b0d2eed.patch?full_index=1"
    sha256 "2fb01154faa3fd8b0fce27eb88049ed9c8f839e706e412399c19c087f7f3b5e1"
  end

  def install
    # Bypass gtk-doc dependency
    ENV["GTKDOCIZE"] = "/bin/true"

    system "autoreconf", "--force", "--install", "--verbose"

    # Only build libuuid (disable all other utilities) to satisfy downstream dependencies
    args = %W[
      --disable-all-programs
      --disable-gtk-doc
      --disable-nls
      --enable-libuuid
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system "true"
  end
end
