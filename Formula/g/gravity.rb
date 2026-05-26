class Gravity < Formula
  desc "Embeddable programming language"
  homepage "https://www.gravity-lang.org/"
  url "https://github.com/marcobambini/gravity/archive/refs/tags/0.9.7.tar.gz"
  sha256 "6f75b995402fa0140e6d9b594c632ef145c1ff7ba80b4e5b65106117fc41984c"
  license "MIT"
  head "https://github.com/marcobambini/gravity.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cfda82beadd19100bd64e330d42113acc82fdf1801ae2fcac798121f74267d95"
  end

  def install
    system "make"
    bin.install "gravity"
    doc.install Dir["docs/*"]
  end

  test do
    (testpath/"hello.gravity").write <<~GRAVITY
      func main() {
          System.print("Hello World!")
      }
    GRAVITY
    system bin/"gravity", "-c", "hello.gravity", "-o", "out.json"
    assert_equal "Hello World!\n", shell_output("#{bin}/gravity -q -x out.json")
    assert_equal "Hello World!\n", shell_output("#{bin}/gravity -q hello.gravity")
  end
end
