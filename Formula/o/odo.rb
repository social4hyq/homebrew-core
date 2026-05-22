class Odo < Formula
  desc "Atomic odometer for the command-line"
  homepage "https://github.com/atomicobject/odo"
  url "https://github.com/atomicobject/odo/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "52133a6b92510d27dfe80c7e9f333b90af43d12f7ea0cf00718aee8a85824df5"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cbd40d668cdf4c60743a0422d6fd622f4f05a6623aa9222843d37aee258f175c"
  end

  conflicts_with "odo-dev", because: "odo-dev also ships 'odo' binary"

  def install
    system "make"
    man1.mkpath
    bin.mkpath
    system "make", "test"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"odo", "testlog"
  end
end
