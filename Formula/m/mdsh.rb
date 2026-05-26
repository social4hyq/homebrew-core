class Mdsh < Formula
  desc "Markdown shell pre-processor"
  homepage "https://zimbatm.github.io/mdsh/"
  url "https://github.com/zimbatm/mdsh/archive/refs/tags/v0.9.2.tar.gz"
  sha256 "4e6aea8fb398f52ec1c2a2bcd2d8238c885aa9bc4b3739a158e64dcc4826dad4"
  license "MIT"
  head "https://github.com/zimbatm/mdsh.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0f4554c39e777582621ecb75c4bdd09525ca1782aa7dbd0c284fdffd59d7d2e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"README.md").write "`$ seq 4 | sort -r`"
    system bin/"mdsh"
    assert_equal <<~MARKDOWN.strip, (testpath/"README.md").read
      `$ seq 4 | sort -r`

      ```
      4
      3
      2
      1
      ```
    MARKDOWN

    assert_match version.to_s, shell_output("#{bin}/mdsh --version")
  end
end
