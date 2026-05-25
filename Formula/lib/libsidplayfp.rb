class Libsidplayfp < Formula
  desc "Library to play Commodore 64 music"
  homepage "https://github.com/libsidplayfp/libsidplayfp"
  url "https://github.com/libsidplayfp/libsidplayfp/releases/download/v3.0.1/libsidplayfp-3.0.1.tar.gz"
  sha256 "6b8ffedc2f631a4ca53258e60468eab3e6a2dc4e1369b2e59e3a5955f99a2143"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25c05d464f2d880ac4b0db63e79f1f2a86430fe2c97e3bd910a22e1ca0be6b09"
  end

  head do
    url "https://github.com/libsidplayfp/libsidplayfp.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "coreutils" => :build
    depends_on "libtool" => :build
    depends_on "xa" => :build
  end

  depends_on "pkgconf" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <sidplayfp/sidplayfp.h>

      int main() {
          sidplayfp play;
          std::cout << LIBSIDPLAYFP_VERSION_MAJ << "."
                    << LIBSIDPLAYFP_VERSION_MIN << "."
                    << LIBSIDPLAYFP_VERSION_LEV;
          return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-L#{lib}", "-I#{include}", "-lsidplayfp", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end
