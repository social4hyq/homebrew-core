class TomlTest < Formula
  desc "Language agnostic test suite for TOML parsers"
  homepage "https://github.com/toml-lang/toml-test"
  url "https://github.com/toml-lang/toml-test/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "fdab2779b3902eb08030f389a5d53e95c5b49404149ac6f2eda5227a5363c232"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1df84574a120fb25eb3a03eee5bccba179eba2bf34d6714ed34999f63207515c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/toml-test"
    pkgshare.install "tests"
  end

  test do
    system bin/"toml-test", "version"
    system bin/"toml-test", "help"

    (testpath/"stub-decoder").write <<~SH
      #!/bin/sh
      cat #{pkgshare}/tests/valid/example.json
    SH

    chmod 0755, testpath/"stub-decoder"
    system bin/"toml-test", "test", "-decoder", testpath/"stub-decoder", "-run", "valid/example*"
  end
end
