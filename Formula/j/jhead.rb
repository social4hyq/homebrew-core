class Jhead < Formula
  desc "Extract Digicam setting info from EXIF JPEG headers"
  homepage "https://github.com/Matthias-Wandel/jhead"
  url "https://github.com/Matthias-Wandel/jhead/archive/refs/tags/3.08.tar.gz"
  sha256 "999a81b489c7b2a7264118f194359ecf4c1b714996a2790ff6d5d2f3940f1e9f"
  license :public_domain

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a879ad3a484d3534f6d740154dcbfc2fe0e5b3edca323eb6489bdddda87821af"
  end

  def install
    ENV.deparallelize
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    cp test_fixtures("test.jpg"), testpath
    system bin/"jhead", "-autorot", "test.jpg"
  end
end
