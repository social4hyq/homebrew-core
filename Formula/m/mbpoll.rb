class Mbpoll < Formula
  desc "Command-line utility to communicate with ModBus slave (RTU or TCP)"
  homepage "https://epsilonrt.fr"
  url "https://github.com/epsilonrt/mbpoll/archive/refs/tags/v1.5.4.tar.gz"
  sha256 "a9bcc3afa3b85b3794505d07827873ead280d96a94769d236892eb8a4fb9956f"
  license "GPL-3.0-only"
  head "https://github.com/epsilonrt/mbpoll.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f471aedee04fe08a44b1b59134a268039aa1dea521e412e88235e610f044b8fd"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libmodbus"

  # fix missing INT_MAX/INT_MIN definitions, upstream pr ref: https://github.com/epsilonrt/mbpoll/pull/105
  patch do
    url "https://github.com/epsilonrt/mbpoll/commit/8a8bd34d803ef8f4daa5aad13eabbe838e2f3fad.patch?full_index=1"
    sha256 "9c663ed9c66e6c62423957a2f19f0916d3ff577433f06f088b721db62c6c080b"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # NOTE: using "1.0-0" and not "1.5.2"
    # upstream fix pr: https://github.com/epsilonrt/mbpoll/pull/58
    assert_match "1.0-0", shell_output("#{bin}/mbpoll -V")

    assert_match "Connection failed", shell_output("#{bin}/mbpoll -1 -o 0.01 -q -m tcp invalid.host 2>&1", 1)
  end
end
