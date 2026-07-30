class Libvidstab < Formula
  desc "Transcode video stabilization plugin"
  homepage "https://github.com/georgmartius/vid.stab"
  url "https://github.com/georgmartius/vid.stab/archive/refs/tags/v1.1.2.tar.gz"
  sha256 "96db34d48a9e3aa13736a48744b56dfb76731ac9bb5193c716de8534c9fd709d"
  license "GPL-2.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "773bba163aac0de88c4112905232216a5cf9e6c67a3224721c447b0f015a26b3"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :test

  def install
    args = %w[
      -DUSE_OMP=OFF
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <vid.stab/libvidstab.h>
      #include <stdio.h>
      int main() {
        printf("libvidstab version: %s\\n", LIBVIDSTAB_VERSION);
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs vidstab").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
