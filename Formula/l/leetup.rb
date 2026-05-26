class Leetup < Formula
  desc "Command-line tool to solve Leetcode problems"
  homepage "https://github.com/dragfire/leetup"
  url "https://github.com/dragfire/leetup/archive/refs/tags/v1.2.5.tar.gz"
  sha256 "f7fd0fed6cab7e352bf6ca5e4d0dd5631d90ef4451e27787236ff4ade36de3b8"
  license "MIT"
  head "https://github.com/dragfire/leetup.git", branch: "master"

  # This repository also contains tags with a trailing letter (e.g., `0.1.5-d`)
  # but it's unclear whether these are stable. If this situation clears up in
  # the future, we may need to modify this to use a regex that also captures
  # the trailing text (i.e., `/^v?(\d+(?:\.\d+)+(?:[._-][a-z])?)$/i`).
  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e10943611bd8945b48b09bee20e5ddd18e3f25f2d7bea7ed38ccb53c2274eb56"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match <<~EOS, shell_output("#{bin}/leetup user --logout")
      User not logged in!
      User logged out!
    EOS

    assert_match version.to_s, shell_output("#{bin}/leetup --version")
  end
end
