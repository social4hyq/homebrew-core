class Lsof < Formula
  desc "Utility to list open files"
  homepage "https://github.com/lsof-org/lsof"
  url "https://github.com/lsof-org/lsof/archive/refs/tags/4.99.6.tar.gz"
  sha256 "2ce65158694e9c44dfc54916f5b843d887763c03128e0a1c77d62ae106537009"
  license "lsof"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e3daa6eaed1fa8598229066c25d96cd4bd37cc714f3df0efb7efbdbdc3ac1db"
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
