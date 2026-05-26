class Brush < Formula
  desc "Bourne RUsty SHell (command interpreter)"
  homepage "https://github.com/reubeno/brush"
  url "https://github.com/reubeno/brush/archive/refs/tags/brush-shell-v0.4.0.tar.gz"
  sha256 "0cce607454972c18bc4a30d2f44a2c91fccf02c458475fda7720370a3dc8a4f0"
  license "MIT"
  head "https://github.com/reubeno/brush.git", branch: "main"

  livecheck do
    url :stable
    regex(/brush-shell[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c71776221dab527fa908dd2bf65f413d52845288d05fa2af4bcf7d8aed93792"
  end

  depends_on "rust" => :build
  def install
    system "cargo", "install", *std_cargo_args(path: "brush-shell")
  end

  test do
    assert_match "brush", shell_output("#{bin}/brush --version")
    assert_equal "homebrew", shell_output("#{bin}/brush -c 'echo homebrew'").chomp
  end
end
