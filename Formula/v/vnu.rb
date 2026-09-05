class Vnu < Formula
  desc "Nu Markup Checker: command-line and server HTML validator"
  homepage "https://validator.github.io/validator/"
  url "https://registry.npmjs.org/vnu-jar/-/vnu-jar-26.8.30.tgz"
  sha256 "2bda313c3dd6d05ada3655085ea12e40b380826fde8f719a44cb4deda6c8c887"
  license "MIT"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f9a277a3eb6a1e11eca52c32e0a8cc76b5be9d176e994d94f3db7c95fa56539c"
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
