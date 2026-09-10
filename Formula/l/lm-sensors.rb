class LmSensors < Formula
  desc "Tools for monitoring the temperatures, voltages, and fans"
  homepage "https://github.com/hramrach/lm-sensors"
  url "https://github.com/hramrach/lm-sensors/archive/refs/tags/V3-6-2.tar.gz"
  version "3.6.2"
  sha256 "c6a0587e565778a40d88891928bf8943f27d353f382d5b745a997d635978a8f0"
  license any_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "12d9fadbed94baab4ac5b964aeae9997914bcb0da146d002f7000cb881432379"
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on :linux

  def install
    args = %W[
      PREFIX=#{prefix}
      BUILD_STATIC_LIB=0
      MANDIR=#{man}
      ETCDIR=#{prefix}/etc
    ]
    system "make", *args
    system "make", *args, "install"
  end

  test do
    assert_match("Usage", shell_output("#{bin}/sensors --help"))
  end
end
