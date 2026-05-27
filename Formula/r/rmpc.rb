class Rmpc < Formula
  desc "Terminal based Media Player Client with album art support"
  homepage "https://mierak.github.io/rmpc/"
  url "https://github.com/mierak/rmpc/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "930019066228d18e9530a8c0d77f10e231ab5efbbbca73b331efcd6fbb47557d"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a06a512fcfd3f18a13b5e6e750c64b4be4a09ea6c77879e682f9ba0cae780fef"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match(/#!\[enable/, shell_output("#{bin}/rmpc config"))
  end
end
