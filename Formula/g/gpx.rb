class Gpx < Formula
  desc "Gcode to x3g converter for 3D printers running Sailfish"
  homepage "https://github.com/markwal/GPX/blob/HEAD/README.md"
  url "https://github.com/markwal/GPX/archive/refs/tags/2.6.8.tar.gz"
  sha256 "0877de07d405e7ced8428caa9dd989ebf90e7bdb7b1c34b85b2d3ee30ed28360"
  license "GPL-2.0-or-later"
  head "https://github.com/markwal/GPX.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2f185e70a28834b1b6362d3efab3a0f1f5ce275d3b0020c0b2050566f6f9f20"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.gcode").write("G28 X Y Z")
    system bin/"gpx", "test.gcode"
  end
end
