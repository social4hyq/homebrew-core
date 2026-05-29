class Gti < Formula
  desc "ASCII-art displaying typo-corrector for commands"
  homepage "https://r-wos.org/hacks/gti"
  url "https://github.com/rwos/gti/archive/refs/tags/v1.9.1.tar.gz"
  sha256 "f8a3afdd3967fe7d88bd1b0b9f5cb62ae04dc9ba458238da91efc213f61a9cf9"
  license "MIT"
  head "https://github.com/rwos/gti.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7db6dde8651c53d1ec161f3568fba8a8db420cb328ff1bee7eb717fe48d0959d"
  end

  def install
    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}"
    bin.install "gti"
    man6.install "gti.6"

    bash_completion.install "completions/gti.bash" => "gti"
    zsh_completion.install "completions/gti.zsh" => "_gti"
  end

  test do
    system bin/"gti", "init"
    assert_path_exists testpath/".git"
  end
end
