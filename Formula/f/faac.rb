class Faac < Formula
  desc "ISO AAC audio encoder"
  homepage "https://sourceforge.net/projects/faac/"
  url "https://github.com/knik0/faac/archive/refs/tags/faac-2.1.tar.gz"
  sha256 "1d4b890c7d767361987d80afdacdd654d23a748b4a273d743c174c2d57e9bce5"
  license "LGPL-2.1-or-later"
  compatibility_version 1
  head "https://github.com/knik0/faac.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f12ceb5ad18eee434d92bbf2a797f30b6b50a4769b85aff49d95de856b8ce618"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    system bin/"faac", test_fixtures("test.mp3"), "-P", "-o", "test.m4a"
    assert_path_exists testpath/"test.m4a"
  end
end
