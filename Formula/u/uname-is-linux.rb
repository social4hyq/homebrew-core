class UnameIsLinux < Formula
  desc "System identity spoofing tool for OHOS: A Linux environment compatibility layer"
  homepage "https://atomgit.com/Harmonybrew/uname-is-linux"
  url "https://atomgit.com/Harmonybrew/uname-is-linux/releases/download/v1.0.0/uname-is-linux-1.0.0.tar.gz"
  sha256 "e2adc9dedd9d15d45515a1bfce9969c92bb471ec8415ad6f85d292a2ce4fbd3d"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4be05bee0fafd83372348487f3a0f4bb9ecb4945d2772572949fb034757c6c6b"
  end

  keg_only "it is a library for explicit LD_PRELOAD injection and should not be linked globally"

  def install
    system ENV.cc, "-O2", "-fPIC", "-shared", "uname.c", "-o", "libuname.so"
    lib.install "libuname.so"
  end

  test do
    assert_predicate lib/"libuname.so", :exist?
  end
end
