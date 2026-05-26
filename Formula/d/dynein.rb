class Dynein < Formula
  desc "DynamoDB CLI"
  homepage "https://github.com/awslabs/dynein"
  url "https://github.com/awslabs/dynein/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "40be5866288f565ac00494910d5dbb266ca0c34d56d50d839bc2c2aad34dc470"
  license "Apache-2.0"
  head "https://github.com/awslabs/dynein.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fdf3723a5959f5d4d38094ca52caaa15e0bea129fd5276105a7c850785666b28"
  end

  depends_on "cmake" => :build # for libz-ng-sys crate
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  uses_from_macos "bzip2"

  on_linux do
    depends_on "openssl@3" # need to build `openssl-sys`
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "To find all tables in all regions", shell_output("#{bin}/dy desc 2>&1", 1)
    assert_match version.to_s, shell_output("#{bin}/dy --version")
  end
end
