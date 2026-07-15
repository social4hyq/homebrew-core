class Libbcg729 < Formula
  desc "Encoder and decoder of the ITU G.729 Annex A/B speech codec"
  homepage "https://www.linphone.org"
  url "https://github.com/BelledonneCommunications/bcg729/archive/refs/tags/1.1.2.tar.gz"
  sha256 "9c22d98c2debc1e37163b8a703f05278ad5d9c03f1c6b373629d8a072092184a"
  license "GPL-3.0-only"
  head "https://github.com/BelledonneCommunications/bcg729.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aeb1dbd17ab85588a451d047ffe1ad89c10e67fca7bcfb71ccdb43f076ef684c"
  end

  depends_on "cmake" => :build

  def install
    # Workaround to build with CMake 4. TODO: Remove next release.
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <bcg729/encoder.h>

      int main() {
        bcg729EncoderChannelContextStruct *enc = initBcg729EncoderChannel(0);
        if (!enc) return 1;

        closeBcg729EncoderChannel(enc);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-o", "test", "-lbcg729"
    system "./test"
  end
end
