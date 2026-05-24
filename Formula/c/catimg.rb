class Catimg < Formula
  desc "Insanely fast image printing in your terminal"
  homepage "https://github.com/posva/catimg"
  url "https://github.com/posva/catimg/archive/refs/tags/v2.8.0.tar.gz"
  sha256 "1f4f54c237cd3b70c8a125044eb2578e8263c12b42d401a42c02c32f10f62548"
  license "MIT"
  head "https://github.com/posva/catimg.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e28dabbaa97ac0eb598ec76bc38d1eb8ccc59f42174fa8b77fb483bb03480ce0"
  end

  depends_on "cmake" => :build

  def install
    args = %W[-DMAN_OUTPUT_PATH=#{man1}]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"catimg", test_fixtures("test.png")
  end
end
