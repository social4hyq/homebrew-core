class Verapdf < Formula
  desc "Open-source industry-supported PDF/A validation"
  homepage "https://verapdf.org/home/"
  url "https://github.com/veraPDF/veraPDF-apps/archive/refs/tags/v1.30.2.tar.gz"
  sha256 "77dfc85544b83784ba4a9d2807bdb3f194b0c22d83904ecf222054ddf10a5347"
  license any_of: ["GPL-3.0-or-later", "MPL-2.0"]
  head "https://github.com/veraPDF/veraPDF-apps.git", branch: "integration"

  livecheck do
    url :stable
    regex(/^v?(\d+\.\d*[02468]\.\d+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60fc0a209f0c6f5ba37738a9cc2cc9dcec25106456e398d7de06ce12f65bf3ee"
  end

  depends_on "maven" => :build
  depends_on "openjdk"

  def install
    ENV["JAVA_HOME"] = Language::Java.java_home
    system "mvn", "clean", "install", "-DskipTests"

    installer_file = Pathname.glob("installer/target/verapdf-izpack-installer-*.jar").first
    system "java", "-DINSTALL_PATH=#{libexec}", "-jar", installer_file, "-options-system"

    bin.install libexec/"verapdf", libexec/"verapdf-gui"
    bin.env_script_all_files libexec, Language::Java.overridable_java_home_env
    prefix.install "tests"
  end

  test do
    with_env(VERAPDF: bin/"verapdf", NO_CD: "1") do
      system prefix/"tests/exit-status.sh"
    end
  end
end
