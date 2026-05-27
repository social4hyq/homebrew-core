class Bam < Formula
  desc "Build system that uses Lua to describe the build process"
  homepage "https://matricks.github.io/bam/"
  url "https://github.com/matricks/bam/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "cc8596af3325ecb18ebd6ec2baee550e82cb7b2da19588f3f843b02e943a15a9"
  license "Zlib"
  head "https://github.com/matricks/bam.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23ce1a099e368cc421054634977c6857992e86e5b253e076a304daba4b65dad5"
  end

  def install
    system "./make_unix.sh"
    bin.install "bam"
  end

  test do
    (testpath/"hello.c").write <<~C
      #include <stdio.h>
      int main() {
        printf("hello\\n");
        return 0;
      }
    C

    (testpath/"bam.lua").write <<~LUA
      settings = NewSettings()
      objs = Compile(settings, Collect("*.c"))
      exe = Link(settings, "hello", objs)
    LUA

    system bin/"bam", "-v"
    assert_equal "hello", shell_output("./hello").chomp
  end
end
