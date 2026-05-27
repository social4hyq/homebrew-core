class Libsigcxx < Formula
  desc "Callback framework for C++"
  homepage "https://libsigcplusplus.github.io/libsigcplusplus/"
  url "https://github.com/libsigcplusplus/libsigcplusplus/releases/download/3.8.1/libsigc++-3.8.1.tar.xz"
  sha256 "4ff41d1474e501d3baeced4c989d154338206ac16471e614376496b63fe252d1"
  license "LGPL-3.0-or-later"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+\.([0-8]\d*?)?[02468](?:\.\d+)*?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80869f9dc3ded5b1ac0dead8ef4e3fd8c3c519ac40905ac1a9ea3c28e9db8a90"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  uses_from_macos "m4" => :build

  def install
    system "meson", "setup", "build", "-Dbuild-examples=false", "-Dbuild-tests=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <string>
      #include <sigc++/sigc++.h>

      void on_print(const std::string& str) {
        std::cout << str;
      }

      int main(int argc, char *argv[]) {
        sigc::signal<void(const std::string&)> signal_print;

        signal_print.connect(sigc::ptr_fun(&on_print));

        signal_print.emit("hello world\\n");
        return 0;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp",
                   "-L#{lib}", "-lsigc-3.0", "-I#{include}/sigc++-3.0", "-I#{lib}/sigc++-3.0/include", "-o", "test"
    assert_match "hello world", shell_output("./test")
  end
end
