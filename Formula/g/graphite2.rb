class Graphite2 < Formula
  desc "Smart font renderer for non-Roman scripts"
  homepage "https://graphite.sil.org/"
  url "https://github.com/silnrsi/graphite/releases/download/1.3.14/graphite2-1.3.14.tgz"
  sha256 "f99d1c13aa5fa296898a181dff9b82fb25f6cc0933dbaa7a475d8109bd54209d"
  license any_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later", "MPL-1.1+"]
  head "https://github.com/silnrsi/graphite.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d90591daae237907e472e359aaae8bb0a17192a49024e8875508dae2ba923e2"
  end

  depends_on "cmake" => :build

  on_linux do
    depends_on "freetype" => :build
  end

  def install
    inreplace "src/CMakeLists.txt", "target_link_libraries(graphite2 c gcc)", "target_link_libraries(graphite2 c)"

    # CMake: Raised required version to 3.5
    cmake_policy_files = %w[CMakeLists.txt src/CMakeLists.txt]
    cmake_files = cmake_policy_files + %w[
      gr2fonttest
      tests/bittwiddling
      tests/json
      tests/sparsetest
      tests/utftest
    ].map { |f| "#{f}/CMakeLists.txt" }

    inreplace cmake_files, "CMAKE_MINIMUM_REQUIRED(VERSION 2.8.0 FATAL_ERROR)", "CMAKE_MINIMUM_REQUIRED(VERSION 3.5)"
    inreplace cmake_policy_files, "cmake_policy(SET CMP0012 NEW)", ""

    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    inreplace lib/"pkgconfig/graphite2.pc", prefix.realpath, opt_prefix
  end

  test do
    resource "testfont" do
      url "https://scripts.sil.org/pub/woff/fonts/Simple-Graphite-Font.ttf"
      sha256 "7e573896bbb40088b3a8490f83d6828fb0fd0920ac4ccdfdd7edb804e852186a"
    end

    resource("testfont").stage do
      shape = shell_output("#{bin}/gr2fonttest Simple-Graphite-Font.ttf 'abcde'")
      assert_match(/67.*36.*37.*38.*71/m, shape)
    end
  end
end
