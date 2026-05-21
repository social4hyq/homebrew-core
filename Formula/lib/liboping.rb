class Liboping < Formula
  desc "C library to generate ICMP echo requests"
  homepage "https://noping.cc/"
  url "https://noping.cc/files/liboping-1.10.0.tar.bz2"
  sha256 "eb38aa93f93e8ab282d97e2582fbaea88b3f889a08cbc9dbf20059c3779d5cd8"
  license "LGPL-2.1-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?liboping[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f23541a94ca29d6e92db6d46cb9d59953d1f4fb9837b6d51a76c60ced4c2f04"
  end

  uses_from_macos "ncurses"
  uses_from_macos "perl"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"

    # move `Net::Oping.3` manpage to man3 dir

    if OS.linux?
      mv prefix/"man/man3/Net::Oping.3", man3
      rm_r prefix/"man"
    else
      mv prefix/"local/share/man/man3/Net::Oping.3pm", man3
      rm_r prefix/"local"
    end
  end

  def caveats
    "Run oping and noping sudo'ed in order to avoid the 'Operation not permitted'"
  end

  test do
    system bin/"oping", "-h"
    system bin/"noping", "-h"
  end
end
