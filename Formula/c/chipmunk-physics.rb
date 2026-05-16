class ChipmunkPhysics < Formula
  desc "2D rigid body physics library written in C"
  # cannot resolve host bug report, https://github.com/slembcke/Chipmunk2D/issues/261
  homepage "https://github.com/slembcke/Chipmunk2D"
  url "https://chipmunk-physics.net/release/Chipmunk-7.x/Chipmunk-7.0.3.tgz"
  mirror "https://www.mirrorservice.org/sites/distfiles.macports.org/chipmunk/Chipmunk-7.0.3.tgz"
  sha256 "048b0c9eff91c27bab8a54c65ad348cebd5a982ac56978e8f63667afbb63491a"
  license "MIT"
  head "https://github.com/slembcke/Chipmunk2D.git", branch: "master"

  livecheck do
    url "https://chipmunk-physics.net/downloads.php"
    regex(/>\s*Chipmunk2D\s+v?(\d+(?:\.\d+)+)\s*</i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6cc51d753dc4f9e08a707f41bf6b009c38c4bdf69faed249a986dc6589a9816"
  end

  depends_on "cmake" => :build

  def install
    inreplace "src/cpHastySpace.c", "#include <sys/sysctl.h>", "#include <linux/sysctl.h>" if OS.linux?

    system "cmake", "-S", ".", "-B", "build", "-DBUILD_DEMOS=OFF", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    doc.install Dir["doc/*"]
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <chipmunk.h>

      int main(void){
        cpVect gravity = cpv(0, -100);
        cpSpace *space = cpSpaceNew();
        cpSpaceSetGravity(space, gravity);

        cpSpaceFree(space);
        return 0;
      }
    C
    system ENV.cc, testpath/"test.c", "-o", testpath/"test", "-pthread",
                   "-I#{include}/chipmunk", "-L#{lib}", "-lchipmunk"
    system "./test"
  end
end
