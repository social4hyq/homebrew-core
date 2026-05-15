class Gimme < Formula
  desc "Shell script to install any Go version"
  homepage "https://github.com/travis-ci/gimme"
  url "https://github.com/travis-ci/gimme/archive/refs/tags/v1.5.6.tar.gz"
  sha256 "50c42ec01505bee0e5b60165a0f577fe1e08fe9278fe3fe4b073c521f781c61e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0dd473d3aee448c3ae890dad390966719ff484ce521208915ff1d5a7e8c2b4d4"
  end

  def install
    bin.install "gimme"
  end

  test do
    system bin/"gimme", "-l"
  end
end
