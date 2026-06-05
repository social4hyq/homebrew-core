class Openssh < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "https://www.openssh.com/"
  url "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.3p1.tar.gz"
  mirror "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.3p1.tar.gz"
  version "10.3p1"
  sha256 "56682a36bb92dcf4b4f016fd8ec8e74059b79a8de25c15d670d731e7d18e45f4"
  license "SSH-OpenSSH"
  revision 2
  compatibility_version 1

  livecheck do
    url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/"
    regex(/href=.*?openssh[._-]v?(\d+(?:\.\d+)+(?:p\d+)?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1aeed4e8a280d1117205244793b31f3bbbfca90de03661b3c1bfa8a602a66851"
  end

  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  uses_from_macos "mandoc" => :build

  # Per-file patches for OHOS portability. Split so upstream version bumps
  # only reject the affected file(s) instead of a multi-file mega-patch.
  %w[
    config.guess config.sub pathnames.h defines.h
    auth.c authfile.c session.c ssh-agent.c sshd-auth.c sshd.c
    ssh.c ssh-keygen.c readconf.c servconf.c hostfile.c mux.c
    misc.c openbsd-compat_xcrypt.c scp.c platform.c
    cipher.c myproposal.h
  ].each do |p|
    patch do
      file "Patches/openssh/#{p}.patch"
    end
  end

  def install

    # Replace @@HOMEBREW_PREFIX@@ placeholders with actual prefix in patched files
    # This must be done before configure so the compiled-in defaults point to
    # the Homebrew prefix rather than system paths.
    files_with_placeholders = %w[
      pathnames.h defines.h ssh-agent.c sshd.c sshd-auth.c
    ]
    files_with_placeholders.each do |f|
      if File.exist?(f)
        content = File.read(f)
        content.gsub!("@@HOMEBREW_PREFIX@@", HOMEBREW_PREFIX)
        File.write(f, content)
      end
    end

    # OHOS SDK system zlib is used (no separate zlib formula needed)
    zlib_rpath = "/opt/ohos-sdk/ohos/native/sysroot/usr/lib/aarch64-linux-ohos"

    ssl_prefix = Formula["openssl@3"].opt_prefix

    args = %W[
      --sysconfdir=#{etc}/ssh
      --without-pam
      --without-ldns
      --without-libedit
      --without-kerberos5
      --without-shadow
      --with-ssl-dir=#{ssl_prefix}
      --without-openssl-header-check
      --without-zlib-version-check
      --without-stackprotect
      --with-hardening=no
      --with-sandbox=no
      --disable-etc-default-login
      --disable-lastlog
      --disable-libutil
      --disable-pututline
      --disable-pututxline
      --disable-strip
      --disable-utmp
      --disable-utmpx
      --disable-wtmp
      --disable-wtmpx
      --with-privsep-path=#{var}/lib/sshd
      --with-pid-dir=#{var}/run
      --with-default-path=#{HOMEBREW_PREFIX}/bin
    ]

    # Set rpaths so binaries work without LD_LIBRARY_PATH on OHOS
    ENV.append "LDFLAGS", "-Wl,-rpath,#{ssl_prefix}/lib"
    ENV.append "LDFLAGS", "-Wl,-rpath,#{zlib_rpath}"

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install-nokeys"

    bin.install_symlink bin/"ssh" => "slogin"

    (var/"lib/sshd").mkpath
    (var/"run").mkpath

    etc.install "ssh_config" => "ssh/ssh_config" unless (etc/"ssh/ssh_config").exist?
    etc.install "sshd_config" => "ssh/sshd_config" unless (etc/"ssh/sshd_config").exist?
    (etc/"ssh").install "moduli" unless (etc/"ssh/moduli").exist?

    # Generate host keys and make them group-readable for sandbox use
    system bin/"ssh-keygen", "-A"
    Dir[etc/"ssh/ssh_host_*_key"].each { |f| File.chmod 0644, f }

    # Fix paths in sshd_config if needed (replaces Cellar-prefix with opt-prefix)
    sshd_config = etc/"ssh/sshd_config"
    if sshd_config.exist?
      # Fix Cellar paths → opt paths
      inreplace sshd_config, prefix, opt_prefix if File.read(sshd_config).include?(prefix.to_s)
      # OHOS sandbox: home directory ownership belongs to sandbox infra, not the app user.
      # OpenSSH's StrictModes refuses group-writable dirs. Disable it.
      inreplace sshd_config, /^#?StrictModes yes$/, "StrictModes no"
      # OHOS: no PAM, disable password auth (publickey only)
      inreplace sshd_config, /^#?PasswordAuthentication yes$/, "PasswordAuthentication no"
      # OHOS: default port changed from 22 to 8022 (non-privileged)
      inreplace sshd_config, /^#?Port 22$/, "Port 8022"
    end
  end

  def caveats
    <<~EOS
      OpenSSH has been installed for OpenHarmony.

      To SSH from this device to other servers (ssh client):
        The ssh client works normally and supports password authentication.

      To allow other machines to SSH INTO this device (sshd server):
        1. Start sshd:
           #{HOMEBREW_PREFIX}/sbin/sshd -D -p 8022

        2. Copy your client's public key into ~/.ssh/authorized_keys, for example:
           mkdir -p ~/.ssh && echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys

        3. Connect from your client (any username works; use ohos as convention):
           ssh ohos@ohos-ip -p 8022

      Your actual identity on the device is the user who launched sshd.

      Note: Password authentication is not supported in sshd on OHOS.
            Use public key authentication instead.
    EOS
  end

  test do
    assert_match "OpenSSH_", shell_output("#{bin}/ssh -V 2>&1")

    port = free_port
    pid = spawn sbin/"sshd", "-D", "-p", port.to_s
    sleep 2
    # Verify sshd started by checking it bound to the port
    assert_path_exists "/proc/#{pid}/status" if File.exist?("/proc")
  ensure
    Process.kill("TERM", pid) if pid
  end
end
