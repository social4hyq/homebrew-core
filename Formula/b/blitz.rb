class Blitz < Formula
  desc "Multi-dimensional array library for C++"
  homepage "https://github.com/blitzpp/blitz/wiki"
  url "https://github.com/blitzpp/blitz/archive/refs/tags/1.0.2.tar.gz"
  sha256 "500db9c3b2617e1f03d0e548977aec10d36811ba1c43bb5ef250c0e3853ae1c2"
  license "Artistic-2.0"
  head "https://github.com/blitzpp/blitz.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c67778743c090142cc6ee66e2f586230e8e8f0dd4acec0157744cf7d2da2dcbd"
  end

  depends_on "cmake" => :build

  uses_from_macos "python" => :build

  def install
    # Workaround to build with CMake 4
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"testfile.cpp").write <<~CPP
      #include <blitz/array.h>
      #include <cstdlib>

      using namespace blitz;
      int main(){
        Array<float,2> A(3,1);
        A = 17, 2, 97;
        cout << "A = " << A << endl;
        return 0;}
    CPP

    system ENV.cxx, "testfile.cpp", "-o", "testfile"
    output = shell_output("./testfile")
    assert_match <<~EOS, output
      A = (0,2) x (0,0)
      [ 17\s
        2\s
        97 ]
    EOS
  end
end
