class Samurai < Formula
  desc "Ninja-compatible build tool written in C"
  homepage "https://github.com/michaelforney/samurai"
  url "https://github.com/michaelforney/samurai/releases/download/1.3/samurai-1.3.tar.gz"
  sha256 "1bc020a9e133432df51911ac71cc34322f828934d9a2282ba2916d88c15976af"
  license "Apache-2.0"
  head "https://github.com/michaelforney/samurai.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7933fcf9434103dfde0f943936e1161c45b5c426ceecda75001918f5f8cecba2"
  end

  # Only link librt on Linux, upstream PR ref, https://github.com/michaelforney/samurai/pull/121
  patch do
    url "https://github.com/michaelforney/samurai/commit/d17ee9ae9448731e7707b4af5824453298ce69d9.patch?full_index=1"
    sha256 "16d65b7857f982085a76d9594ad8899a2b6a2743cb9b8379747cded6facc8dd3"
  end

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    (testpath/"build.ninja").write <<~EOS
      rule cc
        command = #{ENV.cc} $in -o $out
      build hello: cc hello.c
    EOS
    (testpath/"hello.c").write <<~C
      #include <stdio.h>
      int main() {
        puts("Hello, world!");
        return 0;
      }
    C
    system bin/"samu"
    assert_match "Hello, world!", shell_output("./hello")
  end
end
