class Muon < Formula
  desc "Meson-compatible build system"
  homepage "https://muon.build"
  url "https://git.sr.ht/~lattis/muon/archive/0.5.0.tar.gz"
  sha256 "565c1b6e1e58f7e90d8813fda0e2102df69fb493ddab4cf6a84ce3647466bee5"
  license "GPL-3.0-only"
  head "https://git.sr.ht/~lattis/muon", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "af997906fa68ca628e3629be1136b516fd47f342342240a42c868a87a379f8c3"
  end

  depends_on "meson" => :build
  depends_on "scdoc" => :build
  depends_on "libarchive"
  depends_on "ninja"
  depends_on "pkgconf"

  uses_from_macos "curl"

  def install
    args = %w[
      -Dman-pages=enabled
      -Dmeson-docs=disabled
      -Dmeson-tests=disabled
      -Dlibarchive=enabled
      -Dlibcurl=enabled
      -Dlibpkgconf=enabled
      -Dsamurai=disabled
      -Dtracy=disabled
      --force-fallback-for=tinyjson
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"helloworld.c").write <<~C
      #include <stdio.h>
      int main() {
        puts("hi");
        return 0;
      }
    C
    (testpath/"meson.build").write <<~MESON
      project('hello', 'c')
      executable('hello', 'helloworld.c')
    MESON

    system bin/"muon", "setup", "build"
    assert_path_exists testpath/"build/build.ninja"

    system "ninja", "-C", "build", "--verbose"
    assert_equal "hi", shell_output("build/hello").chomp
  end
end
