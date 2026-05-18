class Ipcalc < Formula
  desc "Calculate various network masks, etc. from a given IP address"
  homepage "https://jodies.de/ipcalc"
  url "https://github.com/kjokjo/ipcalc/archive/refs/tags/0.51.tar.gz"
  sha256 "a4dbfaeb7511b81830793ab9936bae9d7b1b561ad33e29106faaaf97ba1c117e"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56eb98fcb3a5e62cead7c856b5fa667176e0167787978ccde19470c78fe5feed"
  end

  def install
    bin.install "ipcalc"
  end

  test do
    system bin/"ipcalc", "--nobinary", "192.168.0.1/24"
  end
end
