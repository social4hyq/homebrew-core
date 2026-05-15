class Cpio < Formula
  desc "Copies files into or out of a cpio or tar archive"
  homepage "https://www.gnu.org/software/cpio/"
  url "https://ftpmirror.gnu.org/gnu/cpio/cpio-2.15.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/cpio/cpio-2.15.tar.bz2"
  sha256 "937610b97c329a1ec9268553fb780037bcfff0dcffe9725ebc4fd9c1aa9075db"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7389219b7c1ef6e4cd991d772c7e2d890a8e133b6547165d7a926f66a7d1754a"
  end

  keg_only :shadowed_by_macos, "macOS provides cpio"

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"

    return if OS.mac?

    # Delete rmt, which causes conflict with `gnu-tar`
    (libexec/"rmt").unlink
    (man8/"rmt.8").unlink
  end

  test do
    (testpath/"test.cc").write <<~CPP
      #include <iostream>
      #include <string>
    CPP
    system "ls #{testpath} | #{bin}/cpio -ov > #{testpath}/directory.cpio"
    assert_path_exists "#{testpath}/directory.cpio"
  end
end
