class Strace < Formula
  desc "Diagnostic, instructional, and debugging tool for the Linux kernel"
  homepage "https://strace.io/"
  url "https://github.com/strace/strace/releases/download/v7.2/strace-7.2.tar.xz"
  sha256 "4bde6246926890dcee824f6e6ac42a06752f47d77e5097d86e3c0d6d4b709fe5"
  license "LGPL-2.1-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf6db043193c64aa6b5c03d6e4bfad5206aa7fb5860976c3e433ec5a05cb7d64"
  end

  head do
    url "https://github.com/strace/strace.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on :linux

  def install
    system "./bootstrap" if build.head?
    system "./configure", "--disable-silent-rules",
                          "--enable-mpers=no", # FIX: configure: error: Cannot enable m32 personality support
                          *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    out = `"strace" "true" 2>&1` # strace the true command, redirect stderr to output
    assert_match "execve(", out
    assert_match "+++ exited with 0 +++", out
  end
end
