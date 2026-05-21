class SpawnFcgi < Formula
  desc "Spawn FastCGI processes"
  homepage "https://redmine.lighttpd.net/projects/spawn-fcgi"
  url "https://www.lighttpd.net/download/spawn-fcgi-1.6.6.tar.gz"
  sha256 "4ffe2e9763cf71ca52c3d642a7bfe20d6be292ba0f2ec07a5900c3110d0e5a85"
  license "BSD-3-Clause"
  head "https://git.lighttpd.net/lighttpd/spawn-fcgi.git", branch: "master"

  livecheck do
    url :head
    regex(/^(?:spawn-fcgi-)?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ca2f39ed1ad3d9ec5349981fec8aa9004b529cf1ced623baf84cde4cd39d1d3"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    system bin/"spawn-fcgi", "--version"
  end
end
