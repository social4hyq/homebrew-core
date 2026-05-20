class Xdelta < Formula
  desc "Binary diff, differential compression tools"
  homepage "https://github.com/jmacd/xdelta"
  url "https://github.com/jmacd/xdelta/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "7515cf5378fca287a57f4e2fee1094aabc79569cfe60d91e06021a8fd7bae29d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cbb4eaf5096793e5e328c161753f0fe643e0db557ff1923d7979bc71e884aa0f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "xz"

  def install
    cd "xdelta3" do
      system "autoreconf", "--force", "--install", "--verbose"
      system "./configure", "--with-liblzma", *std_configure_args
      system "make", "install"
    end
  end

  test do
    system bin/"xdelta3", "config"
  end
end
