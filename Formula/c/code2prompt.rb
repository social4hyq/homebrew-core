class Code2prompt < Formula
  desc "CLI tool to convert your codebase into a single LLM prompt"
  homepage "https://code2prompt.dev/"
  url "https://github.com/mufeedvh/code2prompt/archive/refs/tags/v4.2.0.tar.gz"
  sha256 "de0fe811914bee2d03a0025e734d702d1cb50472dd75c42017cc65ac9435e481"
  license "MIT"
  head "https://github.com/mufeedvh/code2prompt.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "596560d2af9bc283976d6e66672d39a08c0a1cea511001fb6c8851344ea4f7fb"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Ensure the correct `openssl` will be picked up.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args(path: "crates/code2prompt")
  end

  test do
    require "utils/linkage"

    assert_match version.to_s, shell_output("#{bin}/code2prompt --version")

    (testpath/"test.py").write <<~PYTHON
      def hello_world():
          print("Hello, world!")
    PYTHON

    system bin/"code2prompt", "--no-clipboard", "--output-file", "test.json", "--output-format", "json", "test.py"
    json_output = (testpath/"test.json").read
    assert_match "ChatGPT models, text-embedding-ada-002", JSON.parse(json_output)["model_info"]

    [
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert Utils.binary_linked_to_library?(bin/"code2prompt", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
