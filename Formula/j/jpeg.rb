class Jpeg < Formula
  desc "Image manipulation library"
  homepage "https://www.ijg.org/"
  url "https://www.ijg.org/files/jpegsrc.v10.tar.gz"
  mirror "https://fossies.org/linux/misc/jpegsrc.v10.tar.gz"
  sha256 "8b9eaa13242690ebd03e1728ab1edf97a81a78ed6e83624d493655f31ac95ab5"
  license "IJG"

  livecheck do
    url "https://www.ijg.org/files/"
    regex(/href=.*?jpegsrc[._-]v?(\d+[a-z]?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84fdb92cdec2338ca87941c637d5b5eb92f1befcc9c05604d912e5de7305befc"
  end

  keg_only "it conflicts with `jpeg-turbo`"

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    system bin/"djpeg", test_fixtures("test.jpg")
  end
end
