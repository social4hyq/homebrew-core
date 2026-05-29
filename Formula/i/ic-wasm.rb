class IcWasm < Formula
  desc "CLI tool for performing Wasm transformations specific to ICP canisters"
  homepage "https://github.com/dfinity/ic-wasm"
  url "https://github.com/dfinity/ic-wasm/archive/refs/tags/0.9.11.tar.gz"
  sha256 "579e8085c33b7cf37ed2ddc3b9a34dca5dca083201f7648c5d636bab80f75258"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d36b17cd359549b803f63d802eeeb55bc51d3c797379415ef73473a01b0862bd"
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
