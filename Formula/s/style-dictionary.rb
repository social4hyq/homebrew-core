class StyleDictionary < Formula
  desc "Build system for creating cross-platform styles"
  homepage "https://github.com/style-dictionary/style-dictionary"
  url "https://registry.npmjs.org/style-dictionary/-/style-dictionary-5.5.3.tgz"
  sha256 "7abdce80029652a95b53247e2faf03c59e9bee357d07decce9d93c89b5dd784d"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c98a057373548db1b65f22fcae69ec0f88b4022e738f3fc68db483d1ebc3672"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Build an `:all` bottle by removing example files
    examples = libexec/"lib/node_modules/style-dictionary/examples"
    rm %w[
      advanced/create-react-native-app/android/app/proguard-rules.pro
      complete/android/demo/proguard-rules.pro
    ].map { |file| examples/file }
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/style-dictionary --version")

    output = shell_output("#{bin}/style-dictionary init basic")
    assert_match "Source style dictionary starter files created!", output
    assert_path_exists testpath/"config.json"

    output = shell_output("#{bin}/style-dictionary build")
    assert_match "✔︎ build/css/_variables.css", output
    assert_path_exists testpath/"build/css/_variables.css"
  end
end
