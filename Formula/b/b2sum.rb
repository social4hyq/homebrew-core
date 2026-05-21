class B2sum < Formula
  desc "BLAKE2 b2sum reference binary"
  homepage "https://github.com/BLAKE2/BLAKE2"
  url "https://github.com/BLAKE2/BLAKE2/archive/refs/tags/20190724.tar.gz"
  sha256 "7f2c72859d462d604ab3c9b568c03e97b50a4052092205ad18733d254070ddc2"
  license any_of: ["CC0-1.0", "OpenSSL", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa578ab3337d0c9a4abc5b31bed8aa68a4e47f36a30f2e745f53940b2c61524a"
  end

  conflicts_with "coreutils", because: "both install `b2sum` binaries"

  def install
    cd "b2sum" do
      inreplace "makefile", "../sse", "../neon" if Hardware::CPU.arm?
      system "make", "NO_OPENMP=1"
      system "make", "install", "PREFIX=#{prefix}", "MANDIR=#{man}"
    end
  end

  test do
    checksum = "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d1" \
               "7d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923  -"
    assert_equal checksum, pipe_output("#{bin}/b2sum -", "abc", 0).chomp
  end
end
