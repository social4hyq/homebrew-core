class Roundup < Formula
  desc "Unit testing tool"
  homepage "https://bmizerany.github.io/roundup"
  url "https://github.com/bmizerany/roundup/archive/refs/tags/v0.0.6.tar.gz"
  sha256 "20741043ed5be7cbc54b1e9a7c7de122a0dacced77052e90e4ff08e41736f01c"
  license "MIT"
  head "https://github.com/bmizerany/roundup.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6a1124b51468f19924943506b1abe0a5be5f1095da85a7922447ad21620746a7"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--sysconfdir=#{etc}"
    system "make", "SHELL=/bin/bash"
    system "make", "install"
  end

  test do
    system bin/"roundup", "-v"
  end
end
