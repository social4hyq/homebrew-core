class Imagejs < Formula
  desc "Tool to hide JavaScript inside valid image files"
  homepage "https://github.com/jklmnn/imagejs"
  url "https://github.com/jklmnn/imagejs/archive/refs/tags/0.7.2.tar.gz"
  sha256 "ba75c7ea549c4afbcb2a516565ba0b762b5fc38a03a48e5b94bec78bac7dab07"
  license "GPL-3.0-only"
  head "https://github.com/jklmnn/imagejs.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "47c24422e56eff622bcebd5fbd8d5f4ea4a069fd8730d0fc9a6c12b0d1f282fc"
  end

  def install
    system "make"
    bin.install "imagejs"
  end

  test do
    (testpath/"test.js").write "alert('Hello World!')"
    system bin/"imagejs", "bmp", "test.js", "-l"
  end
end
