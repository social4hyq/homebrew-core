class IcWasm < Formula
  desc "CLI tool for performing Wasm transformations specific to ICP canisters"
  homepage "https://github.com/dfinity/ic-wasm"
  url "https://github.com/dfinity/ic-wasm/archive/refs/tags/0.11.0.tar.gz"
  sha256 "5abe32285ff6b652942ac363802350b69fdca47757b245e05e44e810fd7017eb"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "30d71bfed6c8c77e33a081bbf8a06982128a64d6409a92873c37bee0dc05276a"
  end

  depends_on "rust" => :build
  depends_on "wasm-tools" => :test

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Create a wasm module with a custom section for ICP metadata
    (testpath/"test.wat").write '(module (@custom "icp:public abc" "def"))'
    system "wasm-tools", "parse", "test.wat", "-o", "test.wasm"

    # Verify ic-wasm can read the metadata
    assert_equal "def", shell_output("#{bin}/ic-wasm test.wasm metadata abc").strip
  end
end
