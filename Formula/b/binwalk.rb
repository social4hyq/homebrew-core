class Binwalk < Formula
  desc "Searches a binary image for embedded files and executable code"
  homepage "https://github.com/ReFirmLabs/binwalk"
  url "https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "06f595719417b70a592580258ed980237892eadc198e02363201abe6ca59e49a"
  license "MIT"
  head "https://github.com/ReFirmLabs/binwalk.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "85adb75777da77db6d90a305c3c0c37608529051d854b1f2d4e0fe430f9ce31f"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "p7zip"
  depends_on "xz"

  uses_from_macos "bzip2"

  on_linux do
    depends_on "fontconfig"
    depends_on "freetype"
  end

  pypi_packages exclude_packages: ["numpy", "pillow"],
                extra_packages:   %w[capstone gnupg matplotlib pycryptodome]

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    touch "binwalk.test"
    system bin/"binwalk", "binwalk.test"
  end
end
