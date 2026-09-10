class Setconf < Formula
  include Language::Python::Shebang

  desc "Utility for easily changing settings in configuration files"
  homepage "https://setconf.roboticoverlords.org/"
  url "https://setconf.roboticoverlords.org/setconf-0.7.7.tar.xz"
  sha256 "19315574540b3181fec31a4059b9e058381e0192317f153d181e7e7e2aa84d86"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/xyproto/setconf.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b227f96e77d41a180bb0c1f8deb00bee2b13eaee27842fcb6a2d3909ed73ba6b"
  end

  uses_from_macos "python"

  def install
    rewrite_shebang detected_python_shebang(use_python_from_path: true), "setconf.py"
    bin.install "setconf.py" => "setconf"
    man1.install "setconf.1.gz"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/setconf --version")
    system bin/"setconf", "--test"
  end
end
