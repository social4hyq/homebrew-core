class QuickjsNg < Formula
  desc "QuickJS, the Next Generation: a mighty JavaScript engine"
  homepage "https://quickjs-ng.github.io/quickjs/"
  url "https://github.com/quickjs-ng/quickjs/archive/refs/tags/v0.15.0.tar.gz"
  sha256 "d65f951fa9d347a912a53ec2c151bd0ac79bf73d445788e67670ca1b894c67c4"
  license "MIT"
  head "https://github.com/quickjs-ng/quickjs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43b64e06cd944c663df36d152d76ce2b77116bfca5e9233cb0e20cd69daa5c5d"
  end

  depends_on "cmake" => :build

  conflicts_with "quickjs", because: "both install a `qjs` binary"

  def install
    system "cmake", "-S", ".", "-B", "build",
      "-DBUILD_SHARED_LIBS=ON",
      "-DQJS_BUILD_LIBC=ON",
      "-DCMAKE_MACOSX_RPATH=OFF",
      *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    output = shell_output("#{bin}/qjs --eval 'const js=\"JS\"; console.log(`Q${js}${(7 + 35)}`);'")
    assert_match "QJS42", output

    test_file = testpath/"test.js"
    test_file.write "console.log('hello');"
    system bin/"qjsc", test_file
    assert_path_exists testpath/"out.c"
  end
end
