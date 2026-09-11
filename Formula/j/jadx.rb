class Jadx < Formula
  desc "Dex to Java decompiler"
  homepage "https://github.com/skylot/jadx"
  url "https://github.com/skylot/jadx/archive/refs/tags/v1.5.6.tar.gz"
  sha256 "11bb5ebd8c3169ff3f87e6f928d60cff1545f0c55ba1f814ce67e43ba3f2a9e7"
  license "Apache-2.0"
  revision 2
  compatibility_version 1
  head "https://github.com/skylot/jadx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1b6c85e8ab4e8921661e4ac047c6277b74fd16c6fc128510bc7f29901afea24"
  end

  depends_on "gradle" => :build
  depends_on "openjdk"

  def install
    ENV["JADX_VERSION"] = version.to_s if build.stable?

    system "gradle", "clean", "dist"
    libexec.install Dir["build/jadx/*"]
    # HarmonyOS: dev.dirs library doesn't recognize HarmonyOS, set os.name=Linux
    inreplace [libexec/"bin/jadx", libexec/"bin/jadx-gui"] do |s|
      s.gsub!(/^DEFAULT_JVM_OPTS='/, %q{DEFAULT_JVM_OPTS='"-Dos.name=Linux" })
    end

    bin.install libexec/"bin/jadx"
    bin.install libexec/"bin/jadx-gui"
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jadx --version")

    resource "homebrew-test.apk" do
      url "https://raw.githubusercontent.com/facebook/redex/fa32d542d4074dbd485584413d69ea0c9c3cbc98/test/instr/redex-test.apk"
      sha256 "7851cf2a15230ea6ff076639c2273bc4ca4c3d81917d2e13c05edcc4d537cc04"
    end

    resource("homebrew-test.apk").stage do
      system bin/"jadx", "-d", "out", "redex-test.apk"
    end
  end
end
