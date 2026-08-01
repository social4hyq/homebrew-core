class Zuban < Formula
  desc "Python language server and type checker, written in Rust"
  homepage "https://zubanls.com/"
  # pull from git tag to get submodules
  url "https://github.com/zubanls/zuban.git",
    tag:      "v0.9.1",
    revision: "7591e76ed4186437a37da92ca62c4ffbce3de938"
  license "AGPL-3.0-only"
  head "https://github.com/zubanls/zuban.git", branch: "master"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9efdbca4c2fdb53a014062da53a6c44246108d37533747c1ea3efdf7b5711a66"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/zuban")
    libexec.install (buildpath/"third_party/typeshed").children
    bin.env_script_all_files libexec/"bin", ZUBAN_TYPESHED: libexec
  end

  test do
    %w[zmypy zuban].each do |cmd|
      assert_match version.to_s, shell_output("#{bin}/#{cmd} --version")
    end

    (testpath/"t.py").write <<~PY
      def f(x: int) -> int:
        return "nope"
    PY
    out = shell_output("#{bin}/zuban check #{testpath}/t.py 2>&1", 1)
    assert_match "Incompatible return value type", out
  end
end
