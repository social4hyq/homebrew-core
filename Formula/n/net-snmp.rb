class NetSnmp < Formula
  desc "Implements SNMP v1, v2c, and v3, using IPv4 and IPv6"
  homepage "http://www.net-snmp.org/"
  url "https://downloads.sourceforge.net/project/net-snmp/net-snmp/5.9.5.2/net-snmp-5.9.5.2.tar.gz"
  sha256 "16707719f833184a4b72835dac359ae188123b06b5e42817c00790d7dc1384bf"
  license all_of: ["MIT-CMU", "MIT", "BSD-3-Clause"]
  revision 1
  compatibility_version 1
  head "https://github.com/net-snmp/net-snmp.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{url=.*?/net-snmp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56f9ed165a5404d8b9cb81e4fe7de48a0bd9e72b6fcea584387770ed835ae824"
  end

  keg_only :provided_by_macos

  depends_on "openssl@3"

  on_arm do
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # Fix -flat_namespace being used on x86_64 Big Sur and later.
  patch do
    file "Patches/libtool/configure-big_sur.diff"
  end

  def install
    args = [
      "--disable-debugging",
      "--enable-ipv6",
      "--with-defaults",
      "--with-persistent-directory=#{var}/db/net-snmp",
      "--with-logfile=#{var}/log/snmpd.log",
      "--with-mib-modules=host ucd-snmp/diskio",
      "--without-rpm",
      "--without-kmem-usage",
      "--disable-embedded-perl",
      "--without-perl-modules",
      "--with-openssl=#{formula_opt_prefix("openssl@3")}",
    ]

    system "autoreconf", "--force", "--install", "--verbose" if Hardware::CPU.arm?

    # The OHOS SDK's `utmpx.h` defines `struct utmpx` but does not declare
    # `getutxent()`, so `hr_system.c` fails to compile when `HAVE_UTMPX_H` is
    # set. Force the `utmp` API instead, which the SDK provides.
    ENV["ac_cv_header_utmpx_h"] = "no"

    system "./configure", *args, *std_configure_args

    # `libnetsnmptrapd` references symbols from `libnetsnmpagent` (e.g.
    # `send_v2trap`, `run_shell_command`), but the generated link rule only
    # links the mibs and snmp libraries; link the agent library explicitly so
    # the shared library has no unresolved symbols.
    inreplace "apps/Makefile", /^(\t\$\(LIB_LD_CMD\) \$@ \$\{LLIBTRAPD_OBJS\} \$\(MIBLIB\))/,
              "\\1 $(AGENTLIB)"

    system "make"
    # Work around snmptrapd.c:(.text+0x1e0): undefined reference to `dropauth'
    ENV.deparallelize if OS.linux?
    system "make", "install"

    (var/"db/net-snmp").mkpath
    (var/"log").mkpath
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/snmpwalk -V 2>&1")
  end
end
