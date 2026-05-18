class Faac < Formula
  desc "ISO AAC audio encoder"
  homepage "https://sourceforge.net/projects/faac/"
  url "https://github.com/knik0/faac/archive/refs/tags/faac-1.50.tar.gz"
  sha256 "e6876cba00cbd786a7f984d9aaada4d5bcb08d2582100366c70f6164d5c89214"
  license "LGPL-2.1-or-later"
  compatibility_version 1
  head "https://github.com/knik0/faac.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e15128cd96e811bbb5e72c04cea97a778f28e0b74efb23793b6e1a83e3446ab9"
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
