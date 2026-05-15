class EotUtils < Formula
  desc "Tools to convert fonts from OTF/TTF to EOT format"
  homepage "https://www.w3.org/Tools/eot-utils/"
  url "https://www.w3.org/Tools/eot-utils/eot-utilities-1.1.tar.gz"
  sha256 "4eed49dac7052e4147deaddbe025c7dfb404fc847d9fe71e1c42eba5620e6431"
  license "W3C"

  livecheck do
    url :homepage
    regex(/href=.*?eot-utilities[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "03df99cf0ef5c57d458e568a14d4f26fc1cc14ffef6b07ad5f1133cbb4d57c85"
  end

  resource "eot" do
    url "https://github.com/RoelN/font-face-render-check/raw/98f0adda9cfe44fe97f6d538aa893a37905a7add/dev/pixelambacht-dash.eot"
    sha256 "23d6fbe778abe8fe51cfc5ea22f8e061b4c8d32b096ef4a252ba6f2f00406c91"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    resource("eot").stage do
      system bin/"eotinfo", "pixelambacht-dash.eot"
    end
  end
end
