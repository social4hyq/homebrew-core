class Mp3check < Formula
  desc "Tool to check mp3 files for consistency"
  homepage "https://code.google.com/archive/p/mp3check/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mp3check/mp3check-0.8.7.tgz"
  sha256 "27d976ad8495671e9b9ce3c02e70cb834d962b6fdf1a7d437bb0e85454acdd0e"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_tahoe:    "7b728bb5db4fb551bba2fe2ca58a59ae28df476caa8457d4b9ee5d04811d77ac"
    sha256 cellar: :any_skip_relocation, arm64_sequoia:  "5cd5050fc0ece72900fdee9f06144599fd519f2f62fa3ec3f8ed0af1e4805301"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "42c1f2ae16cad1568599d24fbf5ad30f8fab865e9c00dab2fc73eb32eba401d7"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "17d0d21d24eae65edccb72577dbc578d89d1660a7c95eda9c521c2ac27636f6a"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "ae74bb7b036881a560bb8de9ab44ef31cbdfc1d9c710fed0183de39c2fc5272f"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "c0c683cf446e72e17104142e290f2bf3fea6fd01fcf1534ba1c61c7d5a85bb05"
    sha256 cellar: :any_skip_relocation, sonoma:         "5054f3206f9d33b896b7a7f17afd87494d8e8dfaf0e970a2cb53972dd2f2c31e"
    sha256 cellar: :any_skip_relocation, ventura:        "8223c78bae026c58b1e0407a174a3614201b7bb909fcb8ad699973c61ba3406e"
    sha256 cellar: :any_skip_relocation, monterey:       "f798432e9eae61bdf47178e912582b02d9482640375174d26714a59185e626db"
    sha256 cellar: :any_skip_relocation, big_sur:        "943c98e4c93c300a781541927303207319ba030227a0e1dd123fd83abb782ad0"
    sha256 cellar: :any_skip_relocation, catalina:       "a98298c030d1ee1a28e2227ed41970fcad21d2af6486c471d045b07010ac232b"
    sha256 cellar: :any_skip_relocation, arm64_linux:    "8625b856fd021c64af2aac4b515ae9a8be25c0949231f6b7b24ba16b8df75b52"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "72769405fb206a5851bac35ea59bc0d4b7663c57a62cdc8bfa172fa21379130e"
  end

  # Workaround: salsa.debian.org blocks CI server IPs.
  # Fetch the full debian.tar.xz from CDN instead to extract the GCC 9 patch.
  resource "debian-patches" do
    url "https://deb.debian.org/debian/pool/main/m/mp3check/mp3check_0.8.7-6.debian.tar.xz"
    sha256 "891b68a6d3b383ff25ba2d37e2c981aea55fb82785625c74b0f35ce53de9e470"
  end

  def install
    resource("debian-patches").stage do
      patch_file = "patches/fix_ftbfs_with_gcc_9"
      absolute_patch_path = File.expand_path(patch_file)
      system "patch", "-p1", "-i", absolute_patch_path, "-d", buildpath
    end

    ENV.deparallelize
    # The makefile's install target is kinda iffy, but there's
    # only one file to install so it's easier to do it ourselves
    system "make"
    bin.install "mp3check"
  end

  test do
    assert version.to_s, shell_output("#{bin}/mp3check --version")
  end
end
