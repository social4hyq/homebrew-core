class Mago < Formula
  desc "Toolchain for PHP to help developers write better code"
  homepage "https://github.com/carthage-software/mago"
  url "https://github.com/carthage-software/mago/releases/download/1.48.1/source-code.tar.gz"
  sha256 "a32e31e024be1d77b4ecb6677921405777497e4dfbc9263b8f61745993849c9f"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e1e6e82daecc6affbd7afc4b62b3250aff30b0d407c05b16249e4539829a5281"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mago --version")

    (testpath/"example.php").write("<?php echo 'Hello, Mago!';")
    output = shell_output("#{bin}/mago lint . 2>&1")
    assert_match "Missing `declare(strict_types=1);` statement at the beginning of the file", output

    (testpath/"unformatted.php").write("<?php echo 'Unformatted';?>")
    system bin/"mago", "fmt"
    assert_match "<?php echo 'Unformatted';?>", (testpath/"unformatted.php").read
  end
end
