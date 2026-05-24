class Igv < Formula
  desc "Interactive Genomics Viewer"
  homepage "https://igv.org/doc/desktop/"
  url "https://data.broadinstitute.org/igv/projects/downloads/2.19/IGV_2.19.7.zip"
  sha256 "692ae6c3037a6633c33afdbbe960a715f537173f26a16f56a58cb9ccbe163e9f"
  license "MIT"

  livecheck do
    url "https://igv.org/doc/desktop/DownloadPage/"
    regex(/href=.*?IGV[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "584f05a3882b52ae2ffdb4fe8da66d545ad32fef2826824fb8738f9587185e85"
  end

  depends_on "openjdk"

  def install
    inreplace ["igv.sh", "igvtools"], /^prefix=.*/, "prefix=#{libexec}"
    bin.install "igv.sh" => "igv"
    bin.install "igvtools"
    libexec.install "igv.args", "lib"
    bin.env_script_all_files libexec, Language::Java.overridable_java_home_env
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/igvtools")
    assert_match "org/broad/igv/ui/IGV.class", shell_output("#{Formula["openjdk"].bin}/jar tf #{libexec}/lib/igv.jar")

    ENV.append "_JAVA_OPTIONS", "-Duser.home=#{testpath}"
    (testpath/"script").write "exit"
    assert_match "Using system JDK.", shell_output("#{bin}/igv -b script")
  end
end
