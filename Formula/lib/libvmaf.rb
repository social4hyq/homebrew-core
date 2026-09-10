class Libvmaf < Formula
  desc "Perceptual video quality assessment based on multi-method fusion"
  homepage "https://github.com/Netflix/vmaf"
  url "https://github.com/Netflix/vmaf/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "a28f93f3b4fa65601be324587072e32a6a704a304ba7b1aec9b70b3f709bc1dc"
  license "BSD-2-Clause-Patent"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "489643c72a1b314c7691f4d5dc6d240569bf4e113fcee5cee2298968e387174e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  uses_from_macos "vim" => :build # needed for xxd

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    # Fix race condition: test_feature_collector.c includes libvmaf.c
    # which needs vcs_version.h, but meson doesn't declare this dependency.
    inreplace "libvmaf/test/meson.build",
              "['test.c', 'test_feature_collector.c', '../src/log.c', '../src/predict.c', '../src/metadata_handler.c'],",
              "['test.c', 'test_feature_collector.c', '../src/log.c', '../src/predict.c', '../src/metadata_handler.c', rev_target],"
    system "meson", "setup", "build", "libvmaf", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
    pkgshare.install "model"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libvmaf/libvmaf.h>
      int main() {
        return 0;
      }
    C

    flags = [
      "-I#{HOMEBREW_PREFIX}/include/libvmaf",
      "-L#{lib}",
    ]

    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
