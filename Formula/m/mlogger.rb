class Mlogger < Formula
  desc "Log to syslog from the command-line"
  homepage "https://github.com/nbrownus/mlogger"
  url "https://github.com/nbrownus/mlogger/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "141bb9af13a8f0e865c8509ac810c10be4e21f14db5256ef5c7a6731b490bf32"
  license "BSD-4-Clause-UC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9b467551c23318c8c17cb17b75107e42e0b36965f37ab974f7e88c5969c3b8b"
  end

  def install
    system "make"
    bin.install "mlogger"
  end

  test do
    system bin/"mlogger", "-i", "-d", "test"
  end
end
