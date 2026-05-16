class Msktutil < Formula
  desc "Active Directory keytab management"
  homepage "https://github.com/msktutil/msktutil"
  url "https://github.com/msktutil/msktutil/releases/download/1.2.2/msktutil-1.2.2.tar.bz2"
  sha256 "51314bb222c20e963da61724c752e418261a7bfc2408e7b7d619e82a425f6541"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "614d51001ab7709da67247ecb1b605f940467e042a5105205244d60fbac4f714"
  end

  # macos builtin krb5 has `krb5-config reports unknown vendor Apple MITKerberosShim` error
  depends_on "krb5"

  uses_from_macos "cyrus-sasl"
  uses_from_macos "openldap"

  def install
    system "./configure", "--disable-silent-rules",
                          "--mandir=#{man}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{sbin}/msktutil --version")
  end
end
