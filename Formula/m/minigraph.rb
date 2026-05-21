class Minigraph < Formula
  desc "Proof-of-concept seq-to-graph mapper and graph generator"
  homepage "https://lh3.github.io/minigraph"
  url "https://github.com/lh3/minigraph/archive/refs/tags/v0.21.tar.gz"
  sha256 "4272447393f0ae1e656376abe144de96cbafc777414d4c496f735dd4a6d3c06a"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9bda5b327faeeb0cc988a791e8bf20465d255b82fb51ae741eb8c52959cf18f1"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    sse4 = Hardware::CPU.intel? && ((OS.mac? && MacOS.version.requires_sse4?) ||
                                    (!build.bottle? && Hardware::CPU.sse4?))
    unless sse4
      inreplace "Makefile" do |s|
        cflags = s.get_make_var("CFLAGS").split
        cflags.delete("-msse4") { |flag| "Remove inreplace for #{flag}!" }
        s.change_make_var! "CFLAGS", cflags.join(" ")
      end
    end

    system "make"
    bin.install "minigraph"
    pkgshare.install "test"
  end

  test do
    cp_r pkgshare/"test/.", testpath
    output = shell_output("#{bin}/minigraph MT-human.fa MT-orangA.fa 2>&1")
    assert_match "mapped 1 sequences", output
  end
end
