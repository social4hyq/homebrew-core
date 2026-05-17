class Quotatool < Formula
  desc "Edit disk quotas from the command-line"
  homepage "https://quotatool.ekenberg.se/"
  url "https://github.com/ekenberg/quotatool.git",
      tag:      "v1.8.0",
      revision: "cae3d2d9407f2115a96b227542930a5a7ec52ace"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8650e9102325f9de65933575e09eff446e2555ea57cc405a51a4c756c69902c8"
  end

  depends_on :linux

  def install
    system "./configure", "--prefix=#{prefix}"
    sbin.mkpath
    man8.mkpath
    system "make", "install"
  end

  test do
    system sbin/"quotatool", "-V"
  end
end
