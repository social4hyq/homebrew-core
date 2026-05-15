class Gwt < Formula
  desc "Google web toolkit"
  homepage "https://www.gwtproject.org/"
  url "https://github.com/gwtproject/gwt/releases/download/2.13.0/gwt-2.13.0.zip"
  sha256 "43ca936765a432d5e6fb7ce746caf9c9a7d6d47abb955da3f03742d7a61b31d3"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b832926b0e530635cb93f8410ea94486d53c5b04869c6f9324f84b791f1c1ebc"
  end

  depends_on "openjdk"

  def install
    rm Dir["*.cmd"] # remove Windows cmd files
    libexec.install Dir["*"]

    (bin/"i18nCreator").write_env_script libexec/"i18nCreator", Language::Java.overridable_java_home_env
    (bin/"webAppCreator").write_env_script libexec/"webAppCreator", Language::Java.overridable_java_home_env
  end

  test do
    system bin/"webAppCreator", "sh.brew.test"
    assert_path_exists testpath/"src/sh/brew/test.gwt.xml"
  end
end
