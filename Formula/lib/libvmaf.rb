class Libvmaf < Formula
  desc "Perceptual video quality assessment based on multi-method fusion"
  homepage "https://github.com/Netflix/vmaf"
  url "https://github.com/Netflix/vmaf/archive/refs/tags/v3.2.1.tar.gz"
  sha256 "5df7386911bc15fd1ca783132528748d219768ae4fc5f8e0b61184f041648092"
  license "BSD-2-Clause-Patent"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5064864893e5ee2b01f6045492d162b9178115cca992854d2f1a470057534a3a"
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
