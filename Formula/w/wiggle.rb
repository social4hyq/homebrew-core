class Wiggle < Formula
  desc "Program for applying patches with conflicting changes"
  homepage "https://github.com/neilbrown/wiggle"
  url "https://github.com/neilbrown/wiggle/archive/refs/tags/v1.3.tar.gz"
  sha256 "ff92cf0133c1f4dce33563e263cb30e7ddb6f4abdf86d427b1ec1490bec25afa"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82852c506ad9e864cdf7f8af6750a951879d31e651deef4b460a6736e158b3b8"
  end

  uses_from_macos "ncurses"

  def install
    system "make", "OptDbg=#{ENV.cflags}", "PREFIX=#{prefix}", "test", "install"
  end

  test do
    system bin/"wiggle", "--version"
  end
end
