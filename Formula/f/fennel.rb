class Fennel < Formula
  desc "Lua Lisp Language"
  homepage "https://fennel-lang.org"
  url "https://github.com/bakpakin/Fennel/archive/refs/tags/1.6.1.tar.gz"
  sha256 "8bf46040ea9554f4c132de6cb6bf26a30ce8f7c99e58e82bc971c533d91ecd71"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb54aebc4961e8c6fcb11d976e6af9aa852e8fb05004e2f93df9b280c71d4d4f"
  end

  depends_on "luajit" => [:build, :test]
  depends_on "lua"

  def install
    system "make", "PREFIX=#{prefix}", "install"
    system "make", "LUA=luajit", "PREFIX=#{prefix}", "install"
    share.install "man" if OS.mac? # macOS `make` doesn't install the manpages correctly.
  end

  test do
    assert_match "hello, world!", shell_output("#{bin}/fennel -e '(print \"hello, world!\")'")
    system "lua", "-e", "require 'fennel'"
    system "luajit", "-e", "require 'fennel'"
  end
end
