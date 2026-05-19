class Curlcpp < Formula
  desc "Object oriented C++ wrapper for CURL (libcurl)"
  homepage "https://josephp91.github.io/curlcpp"
  url "https://github.com/JosephP91/curlcpp/archive/refs/tags/3.1.tar.gz"
  sha256 "ba7aeed9fde9e5081936fbe08f7a584e452f9ac1199e5fabffbb3cfc95e85f4b"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8cca90f850fdd0b9b7c44ccb8dda0e95231b8cc50023f25eb8135ecf6a7794b9"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  # remove use of CURLOPT_CLOSEPOLICY (removed since curl 8.10+), upstream pr ref, https://github.com/JosephP91/curlcpp/pull/159
  patch do
    on_linux do
      url "https://github.com/JosephP91/curlcpp/commit/bc3800510f30ed74c90227b166d134cd13fd63cf.patch?full_index=1"
      sha256 "0954b32d0304ad9b4acecf3f647242b2c5736f4c6576a390e665e57883dcf10f"
    end
  end

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=SHARED", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <ostream>

      #include "curlcpp/curl_easy.h"
      #include "curlcpp/curl_form.h"
      #include "curlcpp/curl_ios.h"
      #include "curlcpp/curl_exception.h"

      using std::cout;
      using std::endl;
      using std::ostringstream;

      using curl::curl_easy;
      using curl::curl_ios;
      using curl::curl_easy_exception;
      using curl::curlcpp_traceback;

      int main() {
          // Create a stringstream object
          ostringstream str;
          // Create a curl_ios object, passing the stream object.
          curl_ios<ostringstream> writer(str);

          // Pass the writer to the easy constructor and watch the content returned in that variable!
          curl_easy easy(writer);
          easy.add<CURLOPT_URL>("https://google.com");
          easy.add<CURLOPT_FOLLOWLOCATION>(1L);

          try {
              easy.perform();
          } catch (curl_easy_exception &error) {
              // If you want to print the last error.
              std::cerr<<error.what()<<std::endl;

              // If you want to print the entire error stack you can do
              error.print_traceback();
          }
          return 0;
      }
    CPP

    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-lcurlcpp", "-lcurl", "-o", "test"
    system "./test"
  end
end
