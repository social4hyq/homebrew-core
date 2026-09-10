class Lsof < Formula
  desc "Utility to list open files"
  homepage "https://github.com/lsof-org/lsof"
  url "https://github.com/lsof-org/lsof/archive/refs/tags/4.99.7.tar.gz"
  sha256 "bac1b0acbc50aede42fc97dffaa0b0475e97973e36a6351de5f349c6155afc68"
  license "lsof"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "988444e2588e769ccc54df3b3fc75774f90c51386f7451152bd627711fae7476"
  end

  keg_only :provided_by_macos

  on_linux do
    depends_on "libtirpc"
  end

  def install
    if OS.mac?
      ENV["LSOF_INCLUDE"] = MacOS.sdk_path/"usr/include"

      # Source hardcodes full header paths at /usr/include
      inreplace "lib/dialects/darwin/machine.h", "/usr/include", MacOS.sdk_path/"usr/include"
    else
      ENV["LSOF_INCLUDE"] = HOMEBREW_PREFIX/"include"
    end

    ENV["LSOF_CC"] = ENV.cc
    ENV["LSOF_CCV"] = ENV.cxx

    mv "00README", "README"
    # OpenHarmony's netinet/tcp.h has TCP state constants (like glibc), but
    # Configure detects musl and falls through to <linux/tcp.h> which lacks them
    inreplace "lib/dialects/linux/dlsof.h",
              "defined(GLIBCV) || defined(__UCLIBC__) || defined(NEEDS_NETINET_TCPH)",
              "defined(GLIBCV) || defined(__UCLIBC__) || defined(NEEDS_NETINET_TCPH) || defined(__OHOS__)"
    # OpenHarmony lacks getrpcbynumber (legacy sunrpc, not provided by libtirpc).
    # Define HASNORPC_H to skip all RPC-dependent code paths
    inreplace "lib/dialects/linux/dlsof.h",
              "#    if !defined(HASNORPC_H)",
              "#    if defined(__OHOS__)\n#    define HASNORPC_H\n#    endif\n#    if !defined(HASNORPC_H)"
    system "./Configure", "-n", OS.kernel_name.downcase

    system "make"
    bin.install "lsof"
    man8.install "Lsof.8"
  end

  test do
    (testpath/"test").open("w") do
      system bin/"lsof", testpath/"test"
    end
  end
end
