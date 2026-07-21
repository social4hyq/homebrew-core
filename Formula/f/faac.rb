class Faac < Formula
  desc "ISO AAC audio encoder"
  homepage "https://sourceforge.net/projects/faac/"
  url "https://github.com/knik0/faac/archive/refs/tags/faac-2.0.tar.gz"
  sha256 "70bf59db35b2d129c6fe204200427950405d0a63bea3ff8fa8804648dde2cbce"
  license "LGPL-2.1-or-later"
  compatibility_version 1
  head "https://github.com/knik0/faac.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a9caff1e62386e6daf4217f2c978ff5b57cb8eb7013019cc8aa19556ae1a39e"
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
