class Zuban < Formula
  desc "Python language server and type checker, written in Rust"
  homepage "https://zubanls.com/"
  # pull from git tag to get submodules
  url "https://github.com/zubanls/zuban.git",
    tag:      "v0.9.0",
    revision: "392ea3ccc490071706d6736e2d5b2c07e6522386"
  license "AGPL-3.0-only"
  head "https://github.com/zubanls/zuban.git", branch: "master"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ccfb931293c2d972c15af5630ed8930cf0b0e15305fa61b37872dea0bc0d522"
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
