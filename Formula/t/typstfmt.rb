class Typstfmt < Formula
  desc "Formatter for typst"
  homepage "https://github.com/astrale-sharp/typstfmt"
  url "https://github.com/astrale-sharp/typstfmt/archive/refs/tags/0.2.10.tar.gz"
  sha256 "5a3f413a428b2590552c2d0ab0ab04c7a745e1cca128844b7b82ea49326d65c4"
  license one_of: ["MIT", "Apache-2.0"]
  head "https://github.com/astrale-sharp/typstfmt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d1e882636c17846c78c5ea018ee8e31db276b41e11f82d80459e9d18154cb2ff"
  end

  deprecate! date: "2024-06-08", because: :unmaintained
  disable! date: "2025-06-21", because: :unmaintained

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"Hello.typ").write("Hello World!")
    system bin/"typstfmt", "Hello.typ"

    assert_match version.to_s, shell_output("#{bin}/typstfmt --version")
  end
end
