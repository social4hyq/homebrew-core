class Facad < Formula
  desc "Modern, colorful directory listing tool for the command-line"
  homepage "https://github.com/yellow-footed-honeyguide/facad"
  url "https://github.com/yellow-footed-honeyguide/facad/archive/refs/tags/v2.20.16.tar.gz"
  sha256 "4de8b7021efb0ec6f9bf71f0f70cb33e1cf52e945cc99e80760b80767dc380d7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02c48b148ac733e9f23e2b82f4d9c222503db416c15880ad26d75de4add6309e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "facad version #{version}", shell_output("#{bin}/facad --version")

    Dir.mkdir("foobar")
    assert_match "📁 foobar", shell_output(bin/"facad")
  end
end
