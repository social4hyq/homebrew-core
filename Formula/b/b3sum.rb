class B3sum < Formula
  desc "Command-line implementation of the BLAKE3 cryptographic hash function"
  homepage "https://github.com/BLAKE3-team/BLAKE3"
  url "https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.5.tar.gz"
  sha256 "220bd81286e2a0585beac66d41ac3f4c2c33ae8a4e339fc88cf22d5e00514fe9"
  license any_of: [
    "CC0-1.0",
    "Apache-2.0",
    "Apache-2.0" => { with: "LLVM-exception" },
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d24ae83fc8b47004d81fb3d2ade40087c9dccf76d1cac5c320c1c4465f0ed2a"
  end

  depends_on "rust" => :build

  def install
    cd "b3sum" do
      system "cargo", "install", *std_cargo_args
      buildpath.install "README.md"
    end
  end

  test do
    output = pipe_output(bin/"b3sum", "content\n", 0)
    assert_equal "df0c40684c6bda3958244ee330300fdcbc5a37fb7ae06fe886b786bc474be87e  -", output.strip
  end
end
