class B3sum < Formula
  desc "Command-line implementation of the BLAKE3 cryptographic hash function"
  homepage "https://github.com/BLAKE3-team/BLAKE3"
  url "https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.7.tar.gz"
  sha256 "c6782a28842b1c0478524ac06a4f2ede784038ee298d6e2162c0b089c4306a3c"
  license any_of: [
    "CC0-1.0",
    "Apache-2.0",
    "Apache-2.0" => { with: "LLVM-exception" },
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "50e9d484780218d43f66612aad6d5549bd873b7710669cda9823dfaaa058b8ac"
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
