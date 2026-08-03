class Typstyle < Formula
  desc "Beautiful and reliable typst code formatter"
  homepage "https://typstyle-rs.github.io/typstyle/"
  url "https://github.com/typstyle-rs/typstyle/archive/refs/tags/v0.15.1.tar.gz"
  sha256 "0f1b86584a0eb93b0cef374ddcc62508c46ee76cd8b5ede31414260d29a38f12"
  license "Apache-2.0"
  head "https://github.com/typstyle-rs/typstyle.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43a031659c759f41ae6afdbca06fbf602b74dc34e0119b90bd90840bba23221c"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/typstyle")

    generate_completions_from_executable(bin/"typstyle", "completions")
  end

  test do
    (testpath/"Hello.typ").write("Hello World!")
    system bin/"typstyle", "Hello.typ"

    assert_match version.to_s, shell_output("#{bin}/typstyle --version")
  end
end
