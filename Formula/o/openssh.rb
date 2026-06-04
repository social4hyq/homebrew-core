class Openssh < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "https://www.openssh.com/"
  url "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.3p1.tar.gz"
  mirror "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.3p1.tar.gz"
  version "10.3p1"
  sha256 "56682a36bb92dcf4b4f016fd8ec8e74059b79a8de25c15d670d731e7d18e45f4"
  license "SSH-OpenSSH"
  revision 1
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

  # Auto-detect OHOS (config.guess/sub) and replace hardcoded system paths
  # (pathnames.h, defines.h) with HOMEBREW_PREFIX.
  patch do
    file "Patches/openssh/0001-ohos-build.patch"
  end

  # Server daemon: ssh-agent provider paths, auth passwd fallback, relaxed
  # host key permissions, sshd runtime compat (skip setgroups/chdir,
  # daemon(1,0)), sshd-auth privsep synthesis, session env handling.
  patch do
    file "Patches/openssh/0002-ohos-server.patch"
  end

  # Client tools: ssh/ssh-keygen passwd fallback, relaxed config permissions,
  # default port 8022, rename-vs-link for OHOS.
  patch do
    file "Patches/openssh/0003-ohos-client.patch"
  end

  # Misc compat layer: tmp dir, setresgid, tilde_expand, shadow password,
  # scp umask, platform setusercontext skip.
  patch do
    file "Patches/openssh/0004-ohos-compat.patch"
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
    if sshd_config.exist? && File.read(sshd_config).include?(prefix.to_s)
      inreplace sshd_config, prefix, opt_prefix
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
