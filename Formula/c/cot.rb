class Cot < Formula
  desc "Rust web framework for lazy developers"
  homepage "https://cot.rs"
  url "https://github.com/cot-rs/cot/archive/refs/tags/cot-v0.7.0.tar.gz"
  sha256 "8d84e6645e05b213c64e21de4e21200e04cbdcdf934d7b8aa40fa885a1ee74ef"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d1d24b0b12a661466e2124765a3a3ab04c4430816dbb7581328a54d5ea392a4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "cot-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cot --version")

    system bin/"cot", "new", "test-project"
    assert_path_exists testpath/"test-project/Cargo.toml"
  end
end
