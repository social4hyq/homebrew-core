class Air < Formula
  desc "Fast and opinionated formatter for R code"
  homepage "https://github.com/posit-dev/air"
  url "https://github.com/posit-dev/air/archive/refs/tags/0.9.0.tar.gz"
  sha256 "55cae527153badeb348b7b04ffb3c9f1d9f20e27e388edeae694a05a5e32f289"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "83f25ff0f6431dccd6f4b3206b75560a5f6616ebfe60e1f53f8773b92a7dc43f"
  end

  depends_on "rust" => :build

  conflicts_with "go-air", because: "both install binaries with the same name"

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/air")

    generate_completions_from_executable(bin/"air", "generate-shell-completion", shells: [:bash, :zsh, :fish, :pwsh])
  end

  test do
    (testpath/"test.R").write <<~R
      # Simple R code for testing
      x<-1+2
      y <- 3 + 4
      print(x+y)
    R

    assert_match "air #{version}", shell_output("#{bin}/air --version")

    system bin/"air", "format", testpath/"test.R"

    formatted_content = (testpath/"test.R").read
    assert_match "x <- 1 + 2", formatted_content
    assert_match "y <- 3 + 4", formatted_content
  end
end
