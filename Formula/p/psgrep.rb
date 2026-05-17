class Psgrep < Formula
  desc "Shortcut for the 'ps aux | grep' idiom"
  homepage "https://github.com/jvz/psgrep"
  url "https://github.com/jvz/psgrep/archive/refs/tags/1.0.9.tar.gz"
  sha256 "6408e4fc99414367ad08bfbeda6aa86400985efe1ccb1a1f00f294f86dd8b984"
  license "GPL-3.0-or-later"
  head "https://github.com/jvz/psgrep.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "251d3d1c2b9243e7057a63e346c0ce19b29cc6d364ebfeed26963e2fe9dc268a"
  end

  def install
    bin.install "psgrep"
    man1.install "psgrep.1"
  end

  test do
    system bin/"psgrep", Process.pid
    assert_match version.to_s, shell_output("#{bin}/psgrep -v", 2)
  end
end
