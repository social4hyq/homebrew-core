class Jpegoptim < Formula
  desc "Utility to optimize JPEG files"
  homepage "https://github.com/tjko/jpegoptim"
  url "https://github.com/tjko/jpegoptim/archive/refs/tags/v1.5.6.tar.gz"
  sha256 "661a808dfffa933d78c6beb47a2937d572b9f03e94cbaaab3d4c0d72f410e9be"
  license "GPL-3.0-or-later"
  head "https://github.com/tjko/jpegoptim.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79f1c098a3162319d383305f10daf2a2aec1747000f680b110211e2e64713459"
  end

  depends_on "jpeg-turbo"

  def install
    system "./configure", *std_configure_args
    ENV.deparallelize # Install is not parallel-safe
    system "make", "install"
  end

  test do
    source = test_fixtures("test.jpg")
    assert_match "OK", shell_output("#{bin}/jpegoptim --noaction #{source}")
  end
end
