class Shpotify < Formula
  desc "Command-line interface for Spotify on a Mac"
  homepage "https://harishnarayanan.org/projects/shpotify/"
  url "https://github.com/hnarayanan/shpotify/archive/refs/tags/2.1.tar.gz"
  sha256 "b41d8798687be250d0306ac0c5a79420fa46619c5954286711a5d63c86a6c071"
  license "MIT"
  head "https://github.com/hnarayanan/shpotify.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "15c0c4868300c5d33102df60446f2a8b669eb9b2b703bfa31b7647c7c1760991"
  end

  def install
    bin.install "spotify"
  end

  test do
    system bin/"spotify"
  end
end
