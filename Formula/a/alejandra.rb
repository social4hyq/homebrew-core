class Alejandra < Formula
  desc "Command-line tool for formatting Nix Code"
  homepage "https://kamadorueda.com/alejandra/"
  url "https://github.com/kamadorueda/alejandra/archive/refs/tags/4.0.0.tar.gz"
  sha256 "f3f9989c3fb6a56e2050bf5329692fae32a2b54be7c0652aa394afe4660ebb74"
  license "Unlicense"
  head "https://github.com/kamadorueda/alejandra.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9098079746169833da9f31ac19c4f0098ae5282138c478c0bc62e10c497e417f"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "src/alejandra_cli")
  end

  test do
    assert_equal "Alejandra #{version}", shell_output("#{bin}/alejandra --version").chomp

    ENV["LC_ALL"] = "en_US.UTF-8"
    input_nix = "{description=\"Demo\";outputs={self}:{};}"
    output_nix = "{\n  description = \"Demo\";\n  outputs = {self}: {};\n}"

    (testpath/"alejandra_test.nix").write input_nix
    system bin/"alejandra", "alejandra_test.nix"
    assert_equal output_nix, (testpath/"alejandra_test.nix").read.strip
  end
end
