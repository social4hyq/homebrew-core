class Readosm < Formula
  desc "Extract valid data from an Open Street Map input file"
  homepage "https://www.gaia-gis.it/fossil/readosm/index"
  url "https://www.gaia-gis.it/gaia-sins/readosm-sources/readosm-1.1.0a.tar.gz"
  sha256 "db7c051d256cec7ecd4c3775ab9bc820da5a4bf72ffd4e9f40b911d79770f145"
  license any_of: ["MPL-1.1", "GPL-2.0-or-later", "LGPL-2.1-or-later"]

  livecheck do
    url :homepage
    regex(/href=.*?readosm[._-]v?(\d+(?:\.\d+)+[a-z]?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a3268a38606bf3c6e0458df1b7ff395e230f745bf227a93bc186fd3a66be2ad"
  end

  uses_from_macos "expat"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?

    system "./configure", *args, *std_configure_args
    system "make", "install"

    # Install examples but don't include Makefiles or objects
    doc.install "examples"
    rm doc.glob("examples/Makefile*")
    rm doc.glob("examples/*.o")
  end

  test do
    system ENV.cc, doc/"examples/test_osm1.c", "-o", testpath/"test",
                   "-I#{include}", "-L#{lib}", "-lreadosm"
    assert_equal "usage: test_osm1 path-to-OSM-file",
                 shell_output("./test 2>&1", 255).chomp
  end
end
