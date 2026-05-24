class Ol < Formula
  desc "Purely functional dialect of Lisp"
  homepage "https://yuriy-chumak.github.io/ol/"
  url "https://github.com/yuriy-chumak/ol/archive/refs/tags/2.7.tar.gz"
  sha256 "32dec0d527d456cce3273b907ffface6386a61288edf33f8724e2dd1bfb22319"
  license any_of: ["LGPL-3.0-or-later", "MIT"]
  head "https://github.com/yuriy-chumak/ol.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca79bf536ead324a29e4bb407a03182dfdc6bf2ecf0feff879d700710a49b398"
  end

  uses_from_macos "vim" => :build # for xxd

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "make", "all", "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"gcd.ol").write <<~LISP
      (print (gcd 1071 1029))
    LISP
    assert_equal "21", shell_output("#{bin}/ol gcd.ol").strip
  end
end
