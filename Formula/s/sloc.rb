class Sloc < Formula
  desc "Simple tool to count source lines of code"
  homepage "https://github.com/flosse/sloc"
  url "https://registry.npmjs.org/sloc/-/sloc-0.3.2.tgz"
  sha256 "25ac2a41e015a8ee0d0a890221d064ad0288be8ef742c4ec903c84a07e62b347"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "988909c31310bd8ec7c8d7df7368a707ae1a87d16483bbc1cd5f54de5e10be1c"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      int main(void) {
        return 0;
      }
    C

    std_output = <<~EOS
      Path,Physical,Source,Comment,Single-line comment,Block comment,Mixed,Empty block comment,Empty,To Do
      Total,4,4,0,0,0,0,0,0,0
    EOS

    assert_match std_output, shell_output("#{bin}/sloc --format=csv .")
  end
end
