class LinuxHeadersAT68 < Formula
  desc "Header files of the Linux kernel"
  homepage "https://kernel.org/"
  url "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.gz"
  sha256 "1f6134265066aa2bef94103c1e4485d6ed8c2e08ba2a24202ea0c757c6c2c0de"
  license "GPL-2.0-only" => { with: "Linux-syscall-note" }
  revision 1

  livecheck do
    skip "Final kernel.org release for 6.8. Consider adding patches from Ubuntu 24.04."
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "caa253acdc964d1207f22a6323e06ec6d3c177504ab4eadfe906f547afb5bfeb"
  end

  depends_on :linux

  def install
    system "make", "headers"

    cd "usr/include" do
      Pathname.glob("**/*.h").each do |header|
        (include/header.dirname).install header
      end
    end
  end

  test do
    assert_match "KERNEL_VERSION", (include/"linux/version.h").read
  end
end
