class Libnatpmp < Formula
  desc "NAT port mapping protocol library"
  homepage "https://miniupnp.tuxfamily.org/libnatpmp.html"
  url "https://miniupnp.tuxfamily.org/files/download.php?file=libnatpmp-20230423.tar.gz"
  sha256 "0684ed2c8406437e7519a1bd20ea83780db871b3a3a5d752311ba3e889dbfc70"
  license "BSD-3-Clause"

  livecheck do
    url "https://miniupnp.tuxfamily.org/files/"
    regex(/href=.*?libnatpmp[._-]v?(\d{6,8})\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8869f370a6203458887e7703327e83a0a12116a73983d7752057a980d906c924"
  end

  # Fix missing header. Remove when no longer applicable.
  patch do
    url "https://github.com/miniupnp/libnatpmp/commit/5f4a7c65837a56e62c133db33c28cd1ea71db662.patch?full_index=1"
    sha256 "4643048d7e24f8aed4e11e572f3e22f79eae97bb289ae1bbf103b84e8e32f61a"
  end

  def install
    # Reported upstream:
    # https://miniupnp.tuxfamily.org/forum/viewtopic.php?t=978
    inreplace "Makefile", "-Wl,-install_name,$(SONAME)", "-Wl,-install_name,$(INSTALLDIRLIB)/$(SONAME)"
    system "make", "INSTALLPREFIX=#{prefix}", "install"
  end

  test do
    # Use a non-existent gateway.
    output = shell_output("#{bin}/natpmpc -g 0.0.0.0 2>&1", 1)
    [
      "initnatpmp() returned 0 (SUCCESS)",
      "sendpublicaddressrequest returned 2 (SUCCESS)",
      "readnatpmpresponseorretry() failed : the gateway does not support nat-pmp",
    ].each do |expected_match|
      assert_match expected_match, output
    end
  end
end
