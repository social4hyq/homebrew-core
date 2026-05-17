class C < Formula
  desc 'Compile and execute C "scripts" in one go'
  homepage "https://github.com/ryanmjacobs/c"
  url "https://github.com/ryanmjacobs/c/archive/refs/tags/v0.15.1.tar.gz"
  sha256 "ecfad78cb0ab56da44dcfed805f5c261ddefd6dc4a4e57eb2dcfcffa85330605"
  license "MIT"
  head "https://github.com/ryanmjacobs/c.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f6bd9270a40615576a8424ed467135510735fd594e49948bfe36aad9831ca38"
  end

  def install
    bin.install "c"
  end

  test do
    (testpath/"test.c").write("int main(void){return 0;}")
    system bin/"c", testpath/"test.c"
  end
end
