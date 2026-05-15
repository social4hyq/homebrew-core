class Slimerjs < Formula
  desc "Scriptable browser for Web developers"
  homepage "https://slimerjs.org/"
  url "https://github.com/laurentj/slimerjs/archive/refs/tags/1.0.0.tar.gz"
  sha256 "6fd07fa6953e4e497516dd0a7bc5eb2f21c68f9e60bdab080ac2c86e8ab8dfb2"
  license "MPL-2.0"
  head "https://github.com/laurentj/slimerjs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "012c4d63341f139c4cd964711f3fcc431060a2ad209bf69325253662e8a6670c"
  end

  uses_from_macos "zip" => :build

  def install
    ENV["TZ"] = "UTC"

    cd "src" do
      system "zip", "-o", "-X", "-r", "omni.ja", "chrome/", "components/",
        "modules/", "defaults/", "chrome.manifest", "-x@package_exclude.lst"
      libexec.install %w[application.ini omni.ja slimerjs slimerjs.py]
    end
    bin.install_symlink libexec/"slimerjs"
  end

  def caveats
    <<~EOS
      The configuration file was installed in:
        #{libexec}/application.ini
    EOS
  end

  test do
    ENV["SLIMERJSLAUNCHER"] = "/nonexistent"
    assert_match "Set it with the path to Firefox", shell_output("#{bin}/slimerjs test.js", 1)
  end
end
