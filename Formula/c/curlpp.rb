class Curlpp < Formula
  desc "C++ wrapper for libcURL"
  homepage "https://www.curlpp.org/"
  url "https://github.com/jpbarrette/curlpp/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "97e3819bdcffc3e4047b6ac57ca14e04af85380bd93afe314bee9dd5c7f46a0a"
  license "MIT"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c008fe500aca96849b36625641532fc679a568a6299dcf9193f8aa62fdfbdebb"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  patch do
    # build patch for curl 8.10+
    on_linux do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/curlpp/curl-8.10.patch"
      sha256 "77212f725bc4916432bff3cd6ecf009e6a24dcec31048a9311b02af8c9b7b338"
    end
  end

  def install
    ENV.cxx11
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    inreplace bin/"curlpp-config", Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <curlpp/cURLpp.hpp>
      #include <curlpp/Easy.hpp>
      #include <curlpp/Options.hpp>
      #include <curlpp/Exception.hpp>

      int main() {
        try {
          curlpp::Cleanup myCleanup;
          curlpp::Easy myHandle;
          myHandle.setOpt(new curlpp::options::Url("https://google.com"));
          myHandle.perform();
        } catch (curlpp::RuntimeError & e) {
          std::cout << e.what() << std::endl;
          return -1;
        } catch (curlpp::LogicError & e) {
          std::cout << e.what() << std::endl;
          return -1;
        }

        return 0;
      }
    CPP
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", "-I#{include}",
                    "-L#{lib}", "-lcurlpp", "-lcurl"
    system "./test"
  end
end
