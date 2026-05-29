class Epeg < Formula
  desc "JPEG/JPG thumbnail scaling"
  homepage "https://github.com/mattes/epeg"
  url "https://github.com/mattes/epeg/archive/refs/tags/v0.9.3.tar.gz"
  sha256 "efcd7e72c530c3ff46f9efd86ec1dbb042e4a55fc5a7ea75e6ade9f83cf77ba3"
  license "MIT-enna"
  head "https://github.com/mattes/epeg.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b21d15928dbcde9ab99e2e0aec77216433d63d7e1801a4246513a6194e78072"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "jpeg-turbo"
  depends_on "libexif"

  def install
    system "./autogen.sh", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    system bin/"epeg", "--width=1", "--height=1", test_fixtures("test.jpg"), "out.jpg"
    assert_path_exists testpath/"out.jpg"
  end
end
