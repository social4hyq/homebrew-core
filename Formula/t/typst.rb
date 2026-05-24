class Typst < Formula
  desc "Markup-based typesetting system"
  homepage "https://typst.app/"
  url "https://github.com/typst/typst/archive/refs/tags/v0.14.2.tar.gz"
  sha256 "70a56445020ca05efc571c7b07a1a9f52eb93842d420518693c077ae74e54142"
  license "Apache-2.0"
  version_scheme 1
  head "https://github.com/typst/typst.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84edf904c8333d653ea8acb1cc8f0dbe72604ea851d02d35acb6a42baece8e25"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    ENV["TYPST_VERSION"] = version.to_s
    ENV["GEN_ARTIFACTS"] = "artifacts"
    system "cargo", "install", *std_cargo_args(path: "crates/typst-cli")

    man1.install buildpath.glob("crates/typst-cli/artifacts/*.1")
    generate_completions_from_executable(bin/"typst", "completions")
  end

  test do
    (testpath/"Hello.typ").write("Hello World!")
    system bin/"typst", "compile", "Hello.typ", "Hello.pdf"
    assert_path_exists testpath/"Hello.pdf"

    assert_match version.to_s, shell_output("#{bin}/typst --version")
  end
end
