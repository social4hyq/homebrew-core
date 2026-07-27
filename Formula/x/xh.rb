class Xh < Formula
  desc "Friendly and fast tool for sending HTTP requests"
  homepage "https://github.com/ducaale/xh"
  url "https://github.com/ducaale/xh/archive/refs/tags/v0.26.2.tar.gz"
  sha256 "61a88a5b3beac225b75a11d6ed32659af78db7ff29c825def0ab7f4a2906cbd7"
  license "MIT"
  head "https://github.com/ducaale/xh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "96bb166c24d3e75d6dbacf257a026815e34f05c686b9f9aff7a66b4d415717af"
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
