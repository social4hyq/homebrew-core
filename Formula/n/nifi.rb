class Nifi < Formula
  desc "Easy to use, powerful, and reliable system to process and distribute data"
  homepage "https://nifi.apache.org"
  url "https://www.apache.org/dyn/closer.lua?path=/nifi/2.11.0/nifi-2.11.0-bin.zip"
  mirror "https://archive.apache.org/dist/nifi/2.11.0/nifi-2.11.0-bin.zip"
  sha256 "e549acad7e320416b12cb3a902884d0d5458cecd602d1ffd3f26d79081d7f512"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ec6debbcd4036638186f64d70caa0e91b41eb0c92cf939520bfa01f1b9e9343"
  end

  depends_on "openjdk@21"

  def install
    libexec.install Dir["*"]

    (bin/"nifi").write_env_script libexec/"bin/nifi.sh",
                                  Language::Java.overridable_java_home_env("21").merge(NIFI_HOME: libexec)
  end

  test do
    system bin/"nifi", "status"
  end
end
