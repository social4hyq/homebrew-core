class Blockhash < Formula
  desc "Perceptual image hash calculation tool"
  homepage "https://github.com/commonsmachinery/blockhash"
  url "https://github.com/commonsmachinery/blockhash/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "3c48af7bdb1f673b2f3c9f8c0bfa9107a7019b54ac3b4e30964bc0707debdd3a"
  license "MIT"
  revision 5
  head "https://github.com/commonsmachinery/blockhash.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3023d7c3e2c9c864acd6a1da02118e41eeda643d49cc3f7be77688a380a13755"
  end

  depends_on "pkgconf" => :build
  depends_on "imagemagick"

  uses_from_macos "python" => :build

  def install
    system "python3", "./waf", "configure", "--prefix=#{prefix}"
    # pkg-config adds -fopenmp flag during configuring
    # This fails the build on system clang, and OpenMP is not used in blockhash
    inreplace "build/c4che/_cache.py", "-fopenmp", ""
    system "python3", "./waf"
    system "python3", "./waf", "install"
  end

  test do
    resource "homebrew-testdata" do
      url "https://raw.githubusercontent.com/commonsmachinery/blockhash/ce08b465b658c4e886d49ec33361cee767f86db6/testdata/clipper_ship.jpg"
      sha256 "a9f6858876adadc83c8551b664632a9cf669c2aea4fec0c09d81171cc3b8a97f"
    end

    resource("homebrew-testdata").stage testpath
    hash = "00007ff07ff07fe07fe67ff07560600077fe701e7f5e000079fd40410001ffff"
    result = shell_output("#{bin}/blockhash #{testpath}/clipper_ship.jpg")
    assert_match hash, result
  end
end
