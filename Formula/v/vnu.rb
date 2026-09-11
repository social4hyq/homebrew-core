class Vnu < Formula
  desc "Nu Markup Checker: command-line and server HTML validator"
  homepage "https://validator.github.io/validator/"
  url "https://registry.npmjs.org/vnu-jar/-/vnu-jar-26.9.7.tgz"
  sha256 "cce367e472e80baa84211616dbb37a84155cf17dde9d30cd756cf319bb2d5903"
  license "MIT"
  revision 1
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e4bffec0937be58f5f2ebb9b94f839680abc5e2be1e9fdccb74c26eefc3a230f"
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
