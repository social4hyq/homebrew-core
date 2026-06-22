class Vnu < Formula
  desc "Nu Markup Checker: command-line and server HTML validator"
  homepage "https://validator.github.io/validator/"
  url "https://registry.npmjs.org/vnu-jar/-/vnu-jar-26.6.20.tgz"
  sha256 "fd444259e1cc8417f7f2d21b20cc67bb5e6685dc0d4a922f8c7d2c11b8840d73"
  license "MIT"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2c8307d45d75fb4fbf195b62fd6e38b57c196cad850ec6c305ef97671fdfa3e6"
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
