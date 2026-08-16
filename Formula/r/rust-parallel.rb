class RustParallel < Formula
  desc "Run commands in parallel with Rust's Tokio framework"
  homepage "https://github.com/aaronriekenberg/rust-parallel"
  url "https://github.com/aaronriekenberg/rust-parallel/archive/refs/tags/v1.24.0.tar.gz"
  sha256 "9efb8f574ebbe82fad1b89cd94362f75c3b46e7bdf29fc5c640cb9dd10ce2852"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57241d7382229ed23749fd2c16f7413fc9a2c2d3f7c23c57d3e3350eace8f7ce"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    testdata = testpath/"seq"
    testdata.write(1.upto(3).to_a.join("\n"))
    testcmd = "rust-parallel -i #{testdata} echo"
    testset = Array.new(10) { pipe_output(testcmd) }
    refute_equal testset.size, testset.uniq.size
  end
end
