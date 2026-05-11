class Tomlplusplus < Formula
  desc "Header-only TOML config file parser and serializer for C++17"
  homepage "https://marzer.github.io/tomlplusplus/"
  url "https://github.com/marzer/tomlplusplus/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "8517f65938a4faae9ccf8ebb36631a38c1cadfb5efa85d9a72e15b9e97d25155"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "528a7cee8615d0447d91a75b5262a22a6aa0598c9f50cfb4c028a5312a9289ed"
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <toml++/toml.hpp>

      int main()
      {
        std::string tomlContent = R"toml(
          # This is a TOML document

          title = "TOML Example"

          [owner]
          name = "Tom Preston-Werner"
          dob = 1979-05-27T07:32:00-08:00
        )toml";

        auto data = toml::parse(tomlContent);
        std::cout << "Title: " << data["title"].value_or("No title") << std::endl;
        return 0;
      }
    CPP

    pkg_config_flags = shell_output("pkgconf --cflags --libs tomlplusplus").chomp.split
    system ENV.cxx, "test.cpp", *pkg_config_flags, "-std=c++17", "-o", "test"
    assert_match "Title: TOML Example", shell_output("./test")
  end
end
