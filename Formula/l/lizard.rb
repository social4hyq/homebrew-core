class Lizard < Formula
  desc "Efficient compressor with very fast decompression"
  homepage "https://github.com/inikep/lizard"
  url "https://github.com/inikep/lizard/archive/refs/tags/v2.1.tar.gz"
  sha256 "0c1a7efceeb8ae66bfa2b7b659f01dec120925d846b01ce4dfc6960ba8cd61e5"
  license all_of: ["BSD-2-Clause", "GPL-2.0-or-later"]
  version_scheme 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e65637132fe18d34e76d7ef08ed551aaa7ab65b080b3a3b500d19a21fad7427"
  end

  conflicts_with "lizard-analyzer", because: "both install `lizard` binaries"

  def install
    system "make", "PREFIX=#{prefix}", "install"
    cd "examples" do
      system "make"
      (pkgshare/"tests").install "ringBufferHC", "ringBuffer", "lineCompress", "doubleBuffer"
    end
  end

  test do
    (testpath/"tests/test.txt").write <<~EOS
      Homebrew is a free and open-source software package management system that simplifies the installation
      of software on Apple's macOS operating system and Linux. The name means building software on your Mac
      depending on taste. Originally written by Max Howell, the package manager has gained popularity in the
      Ruby on Rails community and earned praise for its extensibility. Homebrew has been recommended for its
      ease of use as well as its integration into the command line. Homebrew is a non-profit project member
      of the Software Freedom Conservancy, and is run entirely by unpaid volunteers.
    EOS

    cp_r pkgshare/"tests", testpath
    cd "tests" do
      system "./ringBufferHC", "./test.txt"
      system "./ringBuffer", "./test.txt"
      system "./lineCompress", "./test.txt"
      system "./doubleBuffer", "./test.txt"
    end
  end
end
