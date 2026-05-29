class Nift < Formula
  desc "Cross-platform open source framework for managing and generating websites"
  homepage "https://nift.dev/"
  url "https://github.com/nifty-site-manager/nsm/archive/refs/tags/v3.0.3.tar.gz"
  sha256 "4900247b92e0ae0d124391ec710a38b322ae83170e2c39191f8ad497090ffd24"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9d963646edf03990302350826d5cfb43faeeb8e35b6e44c3bd8a8fc20eb3b41"
  end

  depends_on "luajit"

  # Fix build on Apple Silicon by removing -pagezero_size/-image_base flags.
  # TODO: Remove if upstream PR is merged and included in release.
  # PR ref: https://github.com/nifty-site-manager/nsm/pull/33
  patch do
    url "https://github.com/nifty-site-manager/nsm/commit/00b3ef1ea5ffe2dedc501f0603d16a9a4d57d395.patch?full_index=1"
    sha256 "c05f0381feef577c493d3b160fc964cee6aeb3a444bc6bde70fda4abc96be8bf"
  end

  # Fix to error: a template argument list is expected after a name prefixed by the template keyword
  # PR ref: https://github.com/nifty-site-manager/nsm/pull/38
  patch do
    url "https://github.com/nifty-site-manager/nsm/commit/d8a54c08a218d6f6823a4e76472708bdc94d1128.patch?full_index=1"
    sha256 "534871043624b409c60d17e08a5e9917ad55ef245df6286d6ea00cc706b3e09f"
  end

  def install
    inreplace "Lua.h", "/usr/local/include", Formula["luajit"].opt_include
    system "make", "BUNDLED=0", "LUAJIT_VERSION=2.1"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    mkdir "empty" do
      system bin/"nsm", "init", ".html"
      assert_path_exists testpath/"empty/output/index.html"
    end
  end
end
