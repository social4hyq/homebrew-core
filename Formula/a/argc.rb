class Argc < Formula
  desc "Easily create and use cli based on bash script"
  homepage "https://github.com/sigoden/argc"
  url "https://github.com/sigoden/argc/archive/refs/tags/v1.24.0.tar.gz"
  sha256 "3c0756bf455759617f2ea0405697d655af15071c89b35a58311e4be53dced1fa"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f75e6b62c8797a9f2202d268b37d6805c9682a30d315c1ef5eebe0a994936f6a"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"argc", "--argc-completions")
  end

  test do
    system bin/"argc", "--argc-create", "build"
    assert_path_exists testpath/"Argcfile.sh"
    assert_match "build", shell_output("#{bin}/argc build")
  end
end
