class Vnu < Formula
  desc "Nu Markup Checker: command-line and server HTML validator"
  homepage "https://validator.github.io/validator/"
  url "https://registry.npmjs.org/vnu-jar/-/vnu-jar-26.7.11.tgz"
  sha256 "4a03229c7163630b17a398f96b5337ca11d5f89c7c7822a3ac39a96a7c912d0b"
  license "MIT"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1eb496b4efcae24fd6a6812721cc6efb837e062fff958f0de40b58e7df3ed73e"
  end

  depends_on "openjdk"

  def install
    libexec.install "build/dist/vnu.jar"
    bin.write_jar_script libexec/"vnu.jar", "vnu"
  end

  test do
    (testpath/"index.html").write <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>hi</title>
      </head>
      <body>
      </body>
      </html>
    HTML
    system bin/"vnu", testpath/"index.html"
  end
end
