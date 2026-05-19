class Kerl < Formula
  desc "Easy building and installing of Erlang/OTP instances"
  homepage "https://github.com/kerl/kerl"
  url "https://github.com/kerl/kerl/archive/refs/tags/4.4.0.tar.gz"
  sha256 "0f32eb08172baffdca9264c5626f6d7fd650369365079fe21f8b8ab997885d8c"
  license "MIT"
  head "https://github.com/kerl/kerl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e419d68e6c3dedefe13416a4bf24361f667f029b156d1eb43fea6e73ba945bbf"
  end

  def install
    bin.install "kerl"

    bash_completion.install "bash_completion/kerl"
    zsh_completion.install "zsh_completion/_kerl"
    fish_completion.install "fish_completion/kerl.fish"
  end

  test do
    system bin/"kerl", "list", "releases"
  end
end
