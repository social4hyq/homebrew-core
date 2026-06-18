class Libkeccak < Formula
  desc "Keccak-family hashing library"
  homepage "https://codeberg.org/maandree/libkeccak"
  url "https://codeberg.org/maandree/libkeccak/archive/1.4.3.tar.gz"
  sha256 "5b28b11b38cc0ea750abd8a3f9cc2463df0e475f06a7a3c3e379471dde3a3d2b"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2eb56d9c744d378797f267e8d81929c9fbf006882eb874a6983b57510720484"
  end

  def install
    args = ["PREFIX=#{prefix}"]
    args << "OSCONFIGFILE=macos.mk" if OS.mac?

    system "make", "install", *args
    pkgshare.install %w[.testfile test.c]
  end

  test do
    cp_r pkgshare/".testfile", testpath
    system ENV.cc, pkgshare/"test.c", "-std=c99", "-O3", "-I#{include}", "-L#{lib}", "-lkeccak", "-o", "test"
    system "./test"
  end
end
