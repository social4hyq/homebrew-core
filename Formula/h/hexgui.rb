class Hexgui < Formula
  desc "GUI for playing Hex over Hex Text Protocol"
  homepage "https://sourceforge.net/p/benzene/hexgui/"
  url "https://github.com/apetresc/hexgui/archive/refs/tags/v0.9.4.tar.gz"
  sha256 "902ebcdf46ac9b90fec6ebd2e24e8d12f2fb291ea4ef711abe407f13c4301eb8"
  license "GPL-3.0-or-later"
  revision 1
  head "https://github.com/apetresc/hexgui.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4382d5ac36b7b70bb0e1d7fc8ab985a75bc3e645815dfe1cd12a29a8ac980e6c"
  end

  depends_on "ant" => :build
  depends_on "openjdk"

  def install
    system "ant"
    libexec.install Dir["*"]
    env = Language::Java.overridable_java_home_env
    env["PATH"] = "$JAVA_HOME/bin:$PATH"
    (bin/"hexgui").write_env_script libexec/"bin/hexgui", env
  end

  test do
    assert_match(/^HexGui #{version} .*/, shell_output("#{bin}/hexgui -version").chomp)
  end
end
