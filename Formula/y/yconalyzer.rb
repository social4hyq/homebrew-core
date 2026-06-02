class Yconalyzer < Formula
  desc "TCP traffic analyzer"
  homepage "https://sourceforge.net/projects/yconalyzer/"
  url "https://downloads.sourceforge.net/project/yconalyzer/yconalyzer-1.0.4.tar.bz2"
  sha256 "3b2bd33ffa9f6de707c91deeb32d9e9a56c51e232be5002fbed7e7a6373b4d5b"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86b7257e21a6f2454080d34d426331034a2825b5d9dec7a2b0e2962d1a35747b"
  end

  uses_from_macos "libpcap"

  # Fix build issues issue on OS X 10.9/clang
  # Patch reported to upstream - https://sourceforge.net/p/yconalyzer/bugs/3/
  patch :p0 do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/yconalyzer/1.0.4.patch"
    sha256 "a4e87fc310565d91496adac9343ba72841bde3b54b4996e774fa3f919c903f33"
  end

  def install
    # Workaround for error: 'strptime' was not declared in this scope
    # Upstream is not maintained
    ENV.append_to_cflags "-include time.h"

    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make"
    chmod 0755, "./install-sh"
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/yconalyzer -p 80 -r #{test_fixtures("test.pcap")}")
    assert_match "Avg Server Data: 311 bytes", output
  end
end
