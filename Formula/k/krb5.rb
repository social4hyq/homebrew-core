class Krb5 < Formula
  desc "Network authentication protocol"
  homepage "https://web.mit.edu/kerberos/"
  url "https://kerberos.org/dist/krb5/1.22/krb5-1.22.2.tar.gz"
  sha256 "3243ffbc8ea4d4ac22ddc7dd2a1dc54c57874c40648b60ff97009763554eaf13"
  # From Fedora: https://src.fedoraproject.org/rpms/krb5/blob/rawhide/f/krb5.spec
  license all_of: [
    "BSD-2-Clause",
    "BSD-2-Clause-first-lines",
    "BSD-3-Clause",
    "BSD-4-Clause",
    "Brian-Gladman-2-Clause",
    "CMU-Mach-nodoc",
    "FSFULLRWD",
    "HPND",
    "HPND-export2-US",
    "HPND-export-US",
    "HPND-export-US-acknowledgement",
    "HPND-export-US-modify",
    "ISC",
    "MIT",
    "MIT-CMU",
    "OLDAP-2.8",
    "OpenVision",
    any_of: ["BSD-2-Clause", "GPL-2.0-or-later"],
  ]
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/Current release: .*?>krb5[._-]v?(\d+(?:\.\d+)+)</i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cbc87e1f6694c37743152f71065362b31ea12604168604e6392ac82a0d419514"
  end

  keg_only :provided_by_macos

  depends_on "openssl@3"

  uses_from_macos "bison" => :build
  uses_from_macos "libedit"

  def install
    cd "src" do
      inreplace "lib/krb5/os/dnsglue.c", 
                "((_res.defdname == NULL) ? NULL : strdup(_res.defdname))",
                "NULL"

      system "./configure", "--disable-nls",
                            "--disable-silent-rules",
                            "--without-system-verto",
                            "--sysconfdir=#{etc}",
                            *std_configure_args
      system "make"
      system "make", "install"
    end

    (etc/"krb5.conf").write <<~EOS
      [libdefaults]
          default_ccache_name = FILE:#{var}/krb5/ccache
          dns_lookup_realm = false
          dns_lookup_kdc = false
    EOS
  end

  test do
    system bin/"krb5-config", "--version"
    assert_match include.to_s, shell_output("#{bin}/krb5-config --cflags")
  end
end
