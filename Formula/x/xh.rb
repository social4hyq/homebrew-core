class Xh < Formula
  desc "Friendly and fast tool for sending HTTP requests"
  homepage "https://github.com/ducaale/xh"
  url "https://github.com/ducaale/xh/archive/refs/tags/v0.26.1.tar.gz"
  sha256 "6c4822374d3b9bacfc50719ffb5653a32fd84344e50fd88b499ed8fc9e52198b"
  license "MIT"
  head "https://github.com/ducaale/xh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf23b918adee79da3f80e75143a3f782c4b921ec7f39e57434db4501daf137ca"
  end

  depends_on "rust" => :build
  depends_on "cmake" => :build

  def install
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"

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
