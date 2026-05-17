class AvroC < Formula
  desc "Data serialization system"
  homepage "https://avro.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=avro/avro-1.12.1/c/avro-c-1.12.1.tar.gz"
  mirror "https://archive.apache.org/dist/avro/avro-1.12.1/c/avro-c-1.12.1.tar.gz"
  sha256 "b64e31b94719499549622aa92f1d96d1742967ced261a0931b63be3bbe907f2c"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fbc8bf230400ad8c386be3b1619c8b86f2a75ae5e405ddccf7cc1b0e96ebf268"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "jansson"
  depends_on "snappy"
  depends_on "xz"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-example" do
      url "https://raw.githubusercontent.com/apache/avro/88538e9f1d6be236ce69ea2e0bdd6eed352c503e/lang/c/examples/quickstop.c"
      sha256 "8108fda370afb0e7be4e213d4e339bd2aabc1801dcd0b600380d81c09e5ff94f"
    end

    testpath.install resource("homebrew-example")
    system ENV.cc, "quickstop.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lavro"
    assert_match "Silent |  (555) 123-6422 | 29 |", shell_output("./test")
  end
end
