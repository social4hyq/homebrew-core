class Openslp < Formula
  desc "Implementation of Service Location Protocol"
  homepage "http://www.openslp.org"
  url "https://downloads.sourceforge.net/project/openslp/2.0.0/2.0.0%20Release/openslp-2.0.0.tar.gz"
  sha256 "924337a2a8e5be043ebaea2a78365c7427ac6e9cee24610a0780808b2ba7579b"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "27a14e2f9f0d05324a855be1a98fd293b1f86bd073675d5237a7f98c559a809d"
  end

  # Last release on 2013-06-08 which has CVEs:
  # * CVE-2016-4912
  # * CVE-2016-7567
  # * CVE-2017-17833
  # * CVE-2019-5544
  deprecate! date: "2026-05-09", because: :unmaintained
  disable! date: "2027-05-09", because: :unmaintained

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    # Workaround for arm64 macOS to use fallback global mutex as USE_APPLE_ATOMICS
    # condition uses deprecated functions and code doesn't compile
    # Issue ref: https://github.com/openslp-org/openslp/issues/19
    inreplace "common/slp_atomic.c", <<~C, "#else\n" if OS.mac? && Hardware::CPU.arm?
      #elif defined(__APPLE__)
      # define USE_APPLE_ATOMICS
      #else
    C

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <slp.h>

      int main(void) {
        SLPHandle hslp;
        SLPError err;
        err = SLPOpen("en", SLP_FALSE, &hslp);
        SLPClose(hslp);
        return err;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lslp"
    system "./test"
  end
end
