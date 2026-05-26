class Zerolang < Formula
  desc "Programming language for agents with explicit effects and predictable memory"
  homepage "https://zerolang.ai/"
  url "https://github.com/vercel-labs/zero/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "97d1cd93fcbb654c88b48435c8ce02e07ac3b57e2ddf1d8d0549681a0695b051"
  license "Apache-2.0"
  head "https://github.com/vercel-labs/zero.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c05912bba0d8d72e55e5324f0b2a4f517f82c88b574ea3fb8f780038c1b74056"
  end

  def install
    system "make", "-C", "native/zero-c", "OUT=#{bin}/zero"
    rm bin/"zero.build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zero --version")

    (testpath/"hello.0").write <<~'ZERO'
      pub fn main Void world World !
        check world.out.write "hello\n"
    ZERO
    system bin/"zero", "check", testpath/"hello.0"
  end
end
