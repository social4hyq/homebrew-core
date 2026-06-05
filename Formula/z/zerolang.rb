class Zerolang < Formula
  desc "Programming language for agents with explicit effects and predictable memory"
  homepage "https://zerolang.ai/"
  url "https://github.com/vercel-labs/zero/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "3d6d1e0ec37d0f4c13fa4f470f6f8679788ebdf19c266b36bfe45f0734e8f5c6"
  license "Apache-2.0"
  head "https://github.com/vercel-labs/zero.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36d4fc8b344c28633b6be2267282a48db8ab2f348afaec12ecf5f7b48bb3b460"
  end

  def install
    system "make", "-C", "native/zero-c", "OUT=#{bin}/zero"
    rm bin/"zero.build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zero --version")

    (testpath/"hello.0").write <<~'ZERO'
      pub fn main(world: World) -> Void raises {
        check world.out.write("hello\n")
      }
    ZERO
    system bin/"zero", "check", testpath/"hello.0"
  end
end
