class Clog < Formula
  desc "Colorized pattern-matching log tail utility"
  homepage "https://gothenburgbitfactory.org/clog/docs/"
  url "https://github.com/GothenburgBitFactory/clog/releases/download/v1.3.0/clog-1.3.0.tar.gz"
  sha256 "fed44a8d398790ab0cf426c1b006e7246e20f3fcd56c0ec4132d24b05d5d2018"
  license "MIT"
  revision 1
  head "https://github.com/GothenburgBitFactory/clog.git", branch: "master"

  livecheck do
    url "https://gothenburgbitfactory.org"
    regex(/href=.*?clog[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de67f4d6b431122f0968a5b5ef6c01be8863df8606e0aa5511f98fcb5c5054bc"
  end

  depends_on "cmake" => :build

  patch do
    file "Patches/clog/0001-add-getenv-home-fallback.patch"
  end

  def install
    # Workaround for CMake 4 compatibility
    args = %w[-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def caveats
    <<~EOS
      Next step is to create a .clogrc file in your home directory. See 'man clog'
      for details and a sample file.
    EOS
  end

  test do
    # Create a rule to suppress any line containing the word 'ignore'
    (testpath/".clogrc").write "default rule /ignore/       --> suppress"

    # Test to ensure that a line that does not match the above rule is not suppressed
    assert_equal "do not suppress", pipe_output("#{bin}/clog --file #{testpath}/.clogrc", "do not suppress").chomp

    # Test to ensure that a line that matches the above rule is suppressed
    assert_empty pipe_output("#{bin}/clog --file #{testpath}/.clogrc", "ignore this line").chomp
  end
end
