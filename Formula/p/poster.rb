class Poster < Formula
  desc "Create large posters out of PostScript pages"
  homepage "https://schrfr.github.io/poster/"
  url "https://github.com/schrfr/poster/archive/refs/tags/1.0.0.tar.gz"
  sha256 "1df49dfd4e50ffd66e0b6e279b454a76329a36280e0dc73b08e5b5dcd5cff451"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "37aa871c83d07e973a8e60cc9624642502a7d66014726bab00059527268b3fdf"
  end

  def install
    system "make"
    bin.install "poster"
    man1.install "poster.1"
  end

  test do
    system bin/"poster", test_fixtures("test.ps")
  end
end
