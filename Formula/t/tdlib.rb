class Tdlib < Formula
  desc "Cross-platform library for building Telegram clients"
  homepage "https://github.com/tdlib/td"
  url "https://github.com/tdlib/td/archive/refs/tags/v1.8.0.tar.gz"
  sha256 "30d560205fe82fb811cd57a8fcbc7ac853a5b6195e9cb9e6ff142f5e2d8be217"
  license "BSL-1.0"
  head "https://github.com/tdlib/td.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7f22d4db4804f4f1e3365f9e1ea5dcacba666ad1b17f0c1ca74d980dc7c4452"
  end

  depends_on "cmake" => :build
  depends_on "gperf" => :build
  depends_on "openssl@3"
  depends_on "readline"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Workaround to build with CMake 4
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"tdjson_example.cpp").write <<~CPP
      #include "td/telegram/td_json_client.h"
      #include <iostream>

      int main() {
        void* client = td_json_client_create();
        if (!client) return 1;
        std::cout << "Client created: " << client;
        return 0;
      }
    CPP

    system ENV.cxx, "tdjson_example.cpp", "-L#{lib}", "-ltdjson", "-o", "tdjson_example"
    assert_match "Client created", shell_output("./tdjson_example")
  end
end
