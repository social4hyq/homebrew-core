class Libsoxr < Formula
  desc "High quality, one-dimensional sample-rate conversion library"
  homepage "https://sourceforge.net/projects/soxr/"
  url "https://downloads.sourceforge.net/project/soxr/soxr-0.1.3-Source.tar.xz"
  sha256 "b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url :stable
    regex(%r{url=.*?/soxr[._-]v?(\d+(?:\.\d+)+)(?:-Source)?\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf028cd540d780c8a532a6c178d34684659c7c6fd4a44f1f06b0f716be70b64a"
  end

  depends_on "cmake" => :build

  # Fixes the build on 64-bit ARM macOS; the __arm__ define used in the
  # code isn't defined on 64-bit Apple Silicon.
  # Upstream pull request: https://sourceforge.net/p/soxr/code/merge-requests/5/
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libsoxr/arm64_defines.patch"
    sha256 "9df5737a21b9ce70cc136c302e195fad9f9f6c14418566ad021f14bb34bb022c"
  end

  def install
    args = %w[
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <soxr.h>

      int main()
      {
        char const *version = 0;
        version = soxr_version();
        if (version == 0)
        {
          return 1;
        }
        return 0;
      }
    C

    system ENV.cc, "-L#{lib}", "test.c", "-lsoxr", "-o", "test"
    system "./test"
  end
end
