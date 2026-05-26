class Decasify < Formula
  desc "Utility for casting strings to title-case according to locale-aware style guides"
  homepage "https://github.com/alerque/decasify"
  url "https://github.com/alerque/decasify/releases/download/v0.11.3/decasify-0.11.3.tar.zst"
  sha256 "2404c9f1c163b4290aeb93694d3ad49181c0a389c3aea7ed6abab22489d14e93"
  license "LGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7363f73c98ab339db4b124d39ffc53cbbab4f0f542cb20adb268e90b317d865"
  end

  head do
    url "https://github.com/alerque/decasify.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  uses_from_macos "jq" => :build, since: :sequoia

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./bootstrap.sh" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "decasify v#{version}", shell_output("#{bin}/decasify --version")
    assert_match "Ben ve İvan", shell_output("#{bin}/decasify -l tr -c title 'ben VE ivan'")
  end
end
