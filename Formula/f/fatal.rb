class Fatal < Formula
  desc "Facebook Template Library"
  homepage "https://www.facebook.com/groups/libfatal/"
  url "https://github.com/facebook/fatal/archive/refs/tags/v2026.08.03.00.tar.gz"
  sha256 "fae471f70d0d6a5b632efc02d272c8c88f458ee462c6426291b2d496c3b46e58"
  license "BSD-3-Clause"
  head "https://github.com/facebook/fatal.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "336f88012956c8db0a919434c470b0c7cbe019b1aef7db7752ff9d4966559d6a"
  end

  def install
    rm "fatal/.clang-tidy"
    include.install "fatal"
    pkgshare.install "demo", "lesson", *buildpath.glob("*.sh")
    inreplace "README.md" do |s|
      s.gsub!("(lesson/)", "(share/fatal/lesson/)")
      s.gsub!("(demo/)", "(share/fatal/demo/)")
    end
  end

  test do
    system ENV.cxx, "-std=c++14", "-I#{include}",
                    include/"fatal/benchmark/test/benchmark_test.cpp",
                    "-o", "benchmark_test"
    system "./benchmark_test"
  end
end
