class ProxychainsNg < Formula
  desc "Hook preloader"
  homepage "https://github.com/rofl0r/proxychains-ng"
  license "GPL-2.0-or-later"
  head "https://github.com/rofl0r/proxychains-ng.git", branch: "master"

  stable do
    url "https://github.com/rofl0r/proxychains-ng/archive/refs/tags/v4.17.tar.gz"
    sha256 "1a2dc68fcbcb2546a07a915343c1ffc75845f5d9cc3ea5eb3bf0b62a66c0196f"

    # Backport fix for incompatible function pointer types
    patch do
      url "https://github.com/rofl0r/proxychains-ng/commit/fffd2532ad34bdf7bf430b128e4c68d1164833c6.patch?full_index=1"
      sha256 "86b5db00415bb7d81a8dc1a3d2429ddafbf135090dc67e57620cd18cd71f3b28"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d2668c5f3c20feaf839da113640e59119c361452e32257b07e79556dea7efd31"
  end

  def install
    system "./configure", *std_configure_args, "--sysconfdir=#{etc}"
    system "make"
    system "make", "install"
    system "make", "install-config"
  end

  test do
    assert_match "config file found", shell_output("#{bin}/proxychains4 test 2>&1", 1)
  end
end
