class OpenBabel < Formula
  desc "Chemical toolbox"
  homepage "https://github.com/openbabel/openbabel"
  url "https://github.com/openbabel/openbabel/archive/refs/tags/openbabel-3-2-1.tar.gz"
  version "3.2.1"
  sha256 "e140c25480fe1678d00b9a52462368fa4e7805fba67b12ee496784437f3e239e"
  license "GPL-2.0-only"
  head "https://github.com/openbabel/openbabel.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b2ecd649f721412c1670e501fe011db912a0d285486749b9e38477b647aada7"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rapidjson" => :build
  depends_on "swig" => :build

  depends_on "cairo"
  depends_on "eigen"
  depends_on "inchi"
  depends_on "python@3.14"

  uses_from_macos "libxml2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def python3
    "python3.14"
  end

  conflicts_with "surelog", because: "both install `roundtrip` binaries"

  def install
    args = %W[
      -DINCHI_INCLUDE_DIR=#{formula_opt_include("inchi")}/inchi
      -DOPENBABEL_USE_SYSTEM_INCHI=ON
      -DRUN_SWIG=ON
      -DPYTHON_BINDINGS=ON
      -DPYTHON_EXECUTABLE=#{which(python3)}
      -DPYTHON_INSTDIR=#{prefix/Language::Python.site_packages(python3)}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match <<~EOS, shell_output("#{bin}/obabel -:'C1=CC=CC=C1Br' -omol")

        7  7  0  0  0  0  0  0  0  0999 V2000
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 C   0  0  0  0  0  0  0  0  0  0  0  0
          0.0000    0.0000    0.0000 Br  0  0  0  0  0  0  0  0  0  0  0  0
        1  6  1  0  0  0  0
        1  2  2  0  0  0  0
        2  3  1  0  0  0  0
        3  4  2  0  0  0  0
        4  5  1  0  0  0  0
        5  6  2  0  0  0  0
        6  7  1  0  0  0  0
      M  END
    EOS

    system python3, "-c", "from openbabel import openbabel"
  end
end
