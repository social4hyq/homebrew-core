class Jxrlib < Formula
  desc "Tools for JPEG-XR image encoding/decoding"
  homepage "https://tracker.debian.org/pkg/jxrlib"
  url "https://deb.debian.org/debian/pool/main/j/jxrlib/jxrlib_1.2~git20170615.f752187.orig.tar.xz"
  version "1.2_git20170615-f752187"
  sha256 "3e3c9d3752b0bbf018ed9ce01b43dcd4be866521dc2370dc9221520b5bd440d4"
  license "BSD-2-Clause"
  version_scheme 1

  livecheck do
    url "https://deb.debian.org/debian/pool/main/j/jxrlib/"
    regex(/href=.*?jxrlib[._-]v?(\d+(?:\.\d+)+[^"' >]*?)\.orig\.t/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map do |match|
        match[0].tr("~", "_").sub(/\.(\h{7})$/, '-\1')
      end
    end
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d56fad7b7b3bddfd162dec418eba47845eb11be6519727c8aef08af8bc25ad0"
  end

  depends_on "cmake" => :build

  # Enable building with CMake. Adapted from Debian patch.
  patch do
    url "https://raw.githubusercontent.com/Gcenx/macports-wine/1b310a17497f9a49cc82789cc5afa2d22bb67c0c/graphics/jxrlib/files/0001-Add-ability-to-build-using-cmake.patch"
    sha256 "beebe13d40bc5b0ce645db26b3c8f8409952d88495bbab8bc3bebc954bdecffe"
  end

  def install
    inreplace "CMakeLists.txt", "@VERSION@", version.to_s
    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    bmp = "Qk06AAAAAAAAADYAAAAoAAAAAQAAAAEAAAABABgAAAAAAAQAAADDDgAAww4AAAAAAAAAAAAA////AA==".unpack1("m")
    infile  = "test.bmp"
    outfile = "test.jxr"
    File.binwrite(infile, bmp)
    system bin/"JxrEncApp", "-i", infile,  "-o", outfile
    system bin/"JxrDecApp", "-i", outfile, "-o", infile
  end
end
