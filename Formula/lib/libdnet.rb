class Libdnet < Formula
  desc "Portable low-level networking library"
  homepage "https://github.com/ofalk/libdnet"
  url "https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-1.18.2.tar.gz"
  sha256 "95611c6d2703f1772fc01ce74acf4ebcc4bcd4315cede35b343bb90dc43bfd8f"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/^libdnet[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b968a6977e6e016244045cf31f5f2a3b3fd7f24a2043b9e5e9c27fbb47a8eb2f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  def install
    # autoreconf to get '.dylib' extension on shared lib
    ENV.append_path "ACLOCAL_PATH", "config"
    system "autoreconf", "--force", "--install", "--verbose"

    system "./configure", "--mandir=#{man}", "--disable-check", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"dnet-config", "--version"
  end
end
