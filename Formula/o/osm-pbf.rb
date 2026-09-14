class OsmPbf < Formula
  desc "Tools related to PBF (an alternative to XML format)"
  homepage "https://wiki.openstreetmap.org/wiki/PBF_Format"
  url "https://github.com/openstreetmap/OSM-binary/archive/refs/tags/v1.8.0.tar.gz"
  sha256 "18ec63e28a42073db62e8fb59134b8bd410c29e8eb1d8ec1759efc9501fbf41a"
  license "LGPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "711f97ca5644b5e30392474ea267ac92e29f5c254b86810e6f05ca0d401f1f82"
  end

  depends_on "cmake" => :build
  depends_on "abseil"
  depends_on "protobuf"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "resources/sample.pbf"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <osmpbf/osmpbf.h>

      int main() {
        OSMPBF::BlobHeader header;
        header.set_type("OSMHeader");
        std::cout << header.type() << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, testpath/"test.cpp",
           "-std=c++17",
           "-I#{include}",
           "-I#{formula_opt_include("protobuf")}",
           "-I#{formula_opt_include("abseil")}",
           "-L#{lib}",
           "-L#{formula_opt_lib("protobuf")}",
           "-L#{formula_opt_lib("abseil")}",
           "-losmpbf",
           "-lprotobuf",
           "-labsl_log_internal_check_op",
           "-labsl_log_internal_message",
           "-o", testpath/"test"

    assert_equal "OSMHeader", shell_output(testpath/"test").chomp
  end
end
