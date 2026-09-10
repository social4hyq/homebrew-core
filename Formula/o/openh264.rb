class Openh264 < Formula
  desc "H.264 codec from Cisco"
  homepage "https://www.openh264.org/"
  url "https://github.com/cisco/openh264/archive/refs/tags/v2.6.0.tar.gz"
  sha256 "558544ad358283a7ab2930d69a9ceddf913f4a51ee9bf1bfb9e377322af81a69"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/cisco/openh264.git", branch: "master"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "251f8998725725bda9d1973733fa587e2ef1a34653a164bf6225c6e2fdfc64aa"
  end

  depends_on "nasm" => :build

  def install
    system "make", "install-shared", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <wels/codec_api.h>
      int main() {
        ISVCDecoder *dec;
        WelsCreateDecoder (&dec);
        WelsDestroyDecoder (dec);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lopenh264", "-o", "test"
    system "./test"
  end
end
