class Astroterm < Formula
  desc "Planetarium for your terminal"
  homepage "https://github.com/da-luce/astroterm"
  url "https://github.com/da-luce/astroterm/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "10a98255a46517ee306be73f156eb78163aff8801f46b84a731f7b5913e1d6f5"
  license "MIT"
  head "https://github.com/da-luce/astroterm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "454951320fc2e7ca13afd9246809c10b1ce1ad202e09135d4e64e3f0c5a44539"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "argtable3"

  uses_from_macos "vim" => :build # for xxd
  uses_from_macos "ncurses"

  resource "bsc5" do
    url "https://distfiles.alpinelinux.org/distfiles/edge/astroterm-bsc5-20231007", using: :nounzip
    mirror "http://tdc-www.harvard.edu/catalogs/BSC5"
    sha256 "e471d02eaf4eecb61c12f879a1cb6432ba9d7b68a9a8c5654a1eb42a0c8cc340"
  end

  def install
    # `mirror` has a different filename, but Homebrew always uses the primary URL's filename
    resource("bsc5").stage do
      (buildpath/"data").install "astroterm-bsc5-20231007" => "bsc5"
    end

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    # astroterm is a TUI application
    assert_match version.to_s, shell_output("#{bin}/astroterm --version")
  end
end
