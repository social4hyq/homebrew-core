class PythonLauncher < Formula
  desc "Launch your Python interpreter the lazy/smart way"
  homepage "https://github.com/brettcannon/python-launcher"
  url "https://github.com/brettcannon/python-launcher/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "6f868da0217b74e05775e7ebcbec4779ce12956728397ea57fd59c8529c56b6d"
  license "MIT"
  head "https://github.com/brettcannon/python-launcher.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "892c3d4ca612705eed0ccacef0add69ab96679fd06302c482365a29c667a6be0"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    man1.install "man-page/py.1"
    fish_completion.install "completions/py.fish"
  end

  test do
    binary = testpath/"python3.6"
    binary.write("Fake Python 3.6 executable")
    with_env("PATH" => testpath) do
      assert_match("3.6 │ #{binary}", shell_output("#{bin}/py --list"))
    end
  end
end
