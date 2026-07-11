class Jadx < Formula
  desc "Dex to Java decompiler"
  homepage "https://github.com/skylot/jadx"
  url "https://github.com/skylot/jadx/archive/refs/tags/v1.5.6.tar.gz"
  sha256 "11bb5ebd8c3169ff3f87e6f928d60cff1545f0c55ba1f814ce67e43ba3f2a9e7"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/skylot/jadx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ce1f26eda3180d197ae6f12a111e46746a1483dfd67d87aca25cd231b5526040"
  end

  depends_on "gradle" => :build
  depends_on "openjdk"

  def install
    ENV["JADX_VERSION"] = version.to_s if build.stable?

    system "gradle", "clean", "dist"
    libexec.install Dir["build/jadx/*"]
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
