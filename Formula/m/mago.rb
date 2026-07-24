class Mago < Formula
  desc "Toolchain for PHP to help developers write better code"
  homepage "https://github.com/carthage-software/mago"
  url "https://github.com/carthage-software/mago/releases/download/1.45.0/source-code.tar.gz"
  sha256 "eb97d09cde4e91df1ce631f46bd0de5ec2d861bf2b35c7db569e97ddb62f9096"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6d2bd6ec09f46fb52af946389d2e55935eab504be2306a0f8883d7e35cc41a6"
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
