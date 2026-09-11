class Vnu < Formula
  desc "Nu Markup Checker: command-line and server HTML validator"
  homepage "https://validator.github.io/validator/"
  url "https://registry.npmjs.org/vnu-jar/-/vnu-jar-26.9.7.tgz"
  sha256 "cce367e472e80baa84211616dbb37a84155cf17dde9d30cd756cf319bb2d5903"
  license "MIT"
  revision 1
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a120066bc72c78cb00a4f4397054ba603fff5bdf33e7a955a089af3e537df497"
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
