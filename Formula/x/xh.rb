class Xh < Formula
  desc "Friendly and fast tool for sending HTTP requests"
  homepage "https://github.com/ducaale/xh"
  url "https://github.com/ducaale/xh/archive/refs/tags/v0.25.3.tar.gz"
  sha256 "ba331c33dc5d222f43cc6ad9f602002817772fd52ae28541976db49f34935ae3"
  license "MIT"
  head "https://github.com/ducaale/xh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf23b918adee79da3f80e75143a3f782c4b921ec7f39e57434db4501daf137ca"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    bin.install_symlink bin/"xh" => "xhs"

    man1.install "doc/xh.1"
    bash_completion.install "completions/xh.bash" => "xh"
    fish_completion.install "completions/xh.fish"
    zsh_completion.install "completions/_xh"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xh --version")
    assert_match "Accept-Encoding: gzip, deflate, br, zstd", shell_output("#{bin}/xh --offline https://httpbin.org/get")
  end
end
