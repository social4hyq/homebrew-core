class Nifi < Formula
  desc "Easy to use, powerful, and reliable system to process and distribute data"
  homepage "https://nifi.apache.org"
  url "https://www.apache.org/dyn/closer.lua?path=/nifi/2.9.0/nifi-2.9.0-bin.zip"
  mirror "https://archive.apache.org/dist/nifi/2.9.0/nifi-2.9.0-bin.zip"
  sha256 "3376074740d632160aa3916104fd8ee7fbb7630eeda5b4ef319bc1a52d9a6e06"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2621316e0df64879df0687f8e5b994234ad5e2dfe6e76eab38d668e3437aed76"
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
