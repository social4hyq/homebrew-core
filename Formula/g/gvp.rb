class Gvp < Formula
  desc "Go versioning packager"
  homepage "https://github.com/pote/gvp"
  url "https://github.com/pote/gvp/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "e1fccefa76495293350d47d197352a63cae6a014d8d28ebdedb785d4304ee338"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "09123ffceea3d156a475085b557c21c9db1de1f6fcf937bb2b888a243c078e70"
  end

  # Upstream fix for "syntax error near unexpected token `;'"
  patch do
    url "https://github.com/pote/gvp/commit/11c4cefd.patch?full_index=1"
    sha256 "19c59c5185d351e05d0b3fbe6a4dba3960c34a804d67fe320e3189271374c494"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"gvp", "in"
    assert File.directory? ".godeps/src"
  end
end
