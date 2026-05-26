class Mask < Formula
  desc "CLI task runner defined by a simple markdown file"
  homepage "https://github.com/jacobdeichert/mask/"
  url "https://github.com/jacobdeichert/mask/archive/refs/tags/mask/0.11.7.tar.gz"
  sha256 "25df4aa1d67d4d9fb7032619951b753be51bb1ec21349316be678b3156ff1874"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be5bf25d26b6feef0962d5696e77840da573e4111c53b50ac4602dbc8705ee27"
  end

  depends_on "rust" => :build

  def install
    cd "mask" do
      system "cargo", "install", *std_cargo_args
    end
  end

  test do
    (testpath/"maskfile.md").write <<~MARKDOWN
      # Example maskfile

      ## hello (name)

      ```sh
      printf "Hello %s!" "$name"
      ```
    MARKDOWN
    assert_equal "Hello Homebrew!", shell_output("#{bin}/mask hello Homebrew")
  end
end
