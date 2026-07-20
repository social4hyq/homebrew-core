class TomeePlus < Formula
  desc "Everything in TomEE Web Profile and JAX-RS, plus more"
  homepage "https://tomee.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=tomee/tomee-10.2.0/apache-tomee-10.2.0-plus.tar.gz"
  mirror "https://archive.apache.org/dist/tomee/tomee-10.2.0/apache-tomee-10.2.0-plus.tar.gz"
  sha256 "57939efc1017d0c215c337e010a6df5013d159e1fc955443a4da687e93c9d0c2"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da596dab75bebca3a4d1376334980a97d20dc57c549a9b56ef2e380274b1d6ac"
  end

  depends_on "openjdk"

  def install
    # Remove Windows scripts
    rm_r(Dir["bin/*.bat"])
    rm_r(Dir["bin/*.bat.original"])
    rm_r(Dir["bin/*.exe"])

    # Install files
    prefix.install %w[NOTICE LICENSE RELEASE-NOTES RUNNING.txt]
    libexec.install Dir["*"]
    (bin/"tomee-plus-startup").write_env_script "#{libexec}/bin/startup.sh",
                                                Language::Java.overridable_java_home_env
  end

  def caveats
    <<~EOS
      The home of Apache TomEE Plus is:
        #{opt_libexec}
      To run Apache TomEE:
        #{opt_libexec}/bin/tomee-plus-startup
    EOS
  end

  test do
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix
    system "#{opt_libexec}/bin/configtest.sh"
  end
end
