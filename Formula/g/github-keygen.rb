class GithubKeygen < Formula
  desc "Bootstrap GitHub SSH configuration"
  homepage "https://github.com/dolmen/github-keygen"
  url "https://github.com/dolmen/github-keygen/archive/refs/tags/v1.401.tar.gz"
  sha256 "0feb346de7927a3bcacadf2122b333041bb7b21b8262230265dc49a2d0f0b7ef"
  license "GPL-3.0-or-later"
  head "https://github.com/dolmen/github-keygen.git", branch: "release"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "744fc1062245bf4f935f255a451e8fb73be3ac6b01c5343c4bf0ede0374078db"
  end

  uses_from_macos "perl"

  def install
    bin.install "github-keygen"
  end

  test do
    system bin/"github-keygen"
  end
end
