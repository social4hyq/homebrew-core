class Beast < Formula
  desc "Bayesian Evolutionary Analysis Sampling Trees"
  homepage "https://beast.community/"
  url "https://github.com/beast-dev/beast-mcmc/archive/refs/tags/v10.5.0.tar.gz"
  sha256 "6287ebbe85e65e44f421b7e9ec3fd17d9a736ff909dfa3b4ab6b1b1fd361b52b"
  license "LGPL-2.1-or-later"
  revision 1
  head "https://github.com/beast-dev/beast-mcmc.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dddd5131753be13e55c9967577082b6115d075f866cb4cf85bb721ac7d219a5a"
  end

  depends_on "ant" => :build
  depends_on "beagle"
  depends_on "openjdk@25"

  def install
    ENV["JAVA_HOME"] = Language::Java.java_home("25")
    system "ant", "linux"
    libexec.install Dir["release/Linux/BEAST_X_v*/*"]
    pkgshare.install_symlink libexec/"examples"
    bin.install Dir[libexec/"bin/*"]

    env = Language::Java.overridable_java_home_env("25")
    env["PATH"] = "${JAVA_HOME}/bin:${PATH}" if OS.linux?
    bin.env_script_all_files libexec/"bin", env
    inreplace libexec/"bin/beast", "/usr/local", HOMEBREW_PREFIX
  end

  test do
    cp pkgshare/"examples/TestXML/ClockModels/testUCRelaxedClockLogNormal.xml", testpath

    # Run fewer generations to speed up tests
    inreplace "testUCRelaxedClockLogNormal.xml", 'chainLength="10000000"',
                                                 'chainLength="100000"'

    # OpenCL is not supported on virtualized arm64 macOS and causes all beast commands to fail
    if OS.mac? && Hardware::CPU.arm? && Hardware::CPU.virtualized?
      output = shell_output("#{bin}/beast testUCRelaxedClockLogNormal.xml 2>&1", 255)
      assert_match "OpenCL error: CL_INVALID_VALUE", output
      return
    end

    system bin/"beast", "testUCRelaxedClockLogNormal.xml"

    %w[ops log trees].each do |ext|
      output = "testUCRelaxedClockLogNormal." + ext
      assert_path_exists testpath/output, "Failed to create #{output}"
    end
  end
end
