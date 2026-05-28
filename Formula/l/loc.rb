class Loc < Formula
  desc "Count lines of code quickly"
  homepage "https://github.com/cgag/loc"
  url "https://github.com/cgag/loc/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "1e8403fd9a3832007f28fb389593cd6a572f719cd95d85619e7bbcf3dbea18e5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f32a90fb022e1c7f423765cd01d8bbf7cd4972c231488f0720b963ad21ac1960"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <stdio.h>
      int main() {
        println("Hello World");
        return 0;
      }
    CPP
    system bin/"loc", "test.cpp"
  end
end
