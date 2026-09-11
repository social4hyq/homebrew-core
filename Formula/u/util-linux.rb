class UtilLinux < Formula
  desc "Collection of Linux utilities"
  homepage "https://github.com/util-linux/util-linux"
  url "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.42/util-linux-2.42.3.tar.xz"
  sha256 "66ac7c0e725278eb2b039e3104f2c91119341d941b41bac7a285c695f940bd57"
  license all_of: [
    "BSD-3-Clause",
    "BSD-4-Clause-UC",
    "GPL-2.0-only",
    "GPL-2.0-or-later",
    "GPL-3.0-or-later",
    "LGPL-2.1-or-later",
    :public_domain,
  ]
  compatibility_version 1

  # The directory listing where the `stable` archive is found uses major/minor
  # version directories, where it's necessary to check inside a directory to
  # find the full version. The newest directory can contain unstable versions,
  # so it could require more than two requests to identify the newest stable
  # version. With this in mind, we simply check the Git tags as a best effort.
  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9d757d1909441e237aa60b27f04c3335e4999cadf375f8a747deaca66b32a80"
  end

  keg_only :shadowed_by_macos, "macOS provides the uuid.h header"

  depends_on "pkgconf" => :build

  uses_from_macos "libxcrypt"
  uses_from_macos "ncurses"
  uses_from_macos "sqlite"

  depends_on "gettext"

  on_linux do
    depends_on "readline"
    depends_on "zlib-ng-compat"

    conflicts_with "bash-completion", because: "both install `mount`, `rfkill`, and `rtcwake` completions"
    conflicts_with "flock", because: "both install `flock` binaries"
    conflicts_with "ossp-uuid", because: "both install `uuid.3` file"
    conflicts_with "rename", because: "both install `rename` binaries"
  end

  # Fix macOS builds
  # https://github.com/util-linux/util-linux/pull/4173
  patch do
    url "https://github.com/util-linux/util-linux/commit/d22edc2f100eb8dd83d3515758565cb73b0d2eed.patch?full_index=1"
    sha256 "2fb01154faa3fd8b0fce27eb88049ed9c8f839e706e412399c19c087f7f3b5e1"
  end

  # OHOS compatibility patches:
  #   shells.c     → stub getusershell/setusershell/endusershell (libc missing)
  #   ipc*.c       → mq_* functions unavailable (header exists, libc lacks them)
  #   lsmem/chmem  → versionsort glibc extension stub
  #   lsfd/file.c  → mqueue probe unavailable on OHOS
  patch do
    file "Patches/util-linux/0001-adapt-to-ohos.patch"
  end

  def install
    # Bypass gtk-doc dependency
    ENV["GTKDOCIZE"] = "/bin/true"

    # versionsort and strverscmp are glibc extensions; OHOS libc doesn't provide them.
    # Fall back to POSIX alphasort / strcmp (no version-sort semantics, but compiles).
    ENV.append_to_cflags "-Dversionsort=alphasort"
    ENV.append_to_cflags "-Dstrverscmp=strcmp"

    args = %W[
      --disable-silent-rules
      --disable-asciidoc
      --with-bashcompletiondir=#{bash_completion}
    ]

    if OS.mac?
      # Support very old ncurses used on macOS 13 and earlier
      # https://github.com/util-linux/util-linux/issues/2389
      ENV.append_to_cflags "-D_XOPEN_SOURCE_EXTENDED" if MacOS.version <= :ventura

      args << "--disable-bits" # does not build on macOS
      args << "--disable-ipcs" # does not build on macOS
      args << "--disable-ipcrm" # does not build on macOS
      args << "--disable-wall" # already comes with macOS
      args << "--disable-liblastlog2" # does not build on macOS
      args << "--disable-libmount" # does not build on macOS
      args << "--enable-libuuid" # conflicts with ossp-uuid
    else
      # OHOS / Linux: let configure auto-detect what can build.
      # Only disable things that are guaranteed to fail at compile time
      # or would conflict with other packages.

      # ---- Libraries ----
      args << "--enable-libuuid" # conflicts with ossp-uuid
      args << "--disable-liblastlog2"

      # ---- PAM-dependent (login/auth) ----
      args << "--disable-login"
      args << "--disable-su"
      args << "--disable-runuser"
      args << "--disable-chfn-chsh"
      args << "--disable-sulogin"
      args << "--disable-nologin"
      args << "--disable-newgrp"
      args << "--disable-vipw"

      # ---- Compile failures on OHOS ----
      args << "--disable-wall"          # getutxent() returns int instead of struct utmpx*

      # ---- Conflicts ----
      args << "--disable-kill"         # conflicts with coreutils

      # ---- Install-time hardening (no setuid on OHOS) ----
      args << "--disable-use-tty-group"
      args << "--disable-makeinstall-chown"
      args << "--disable-makeinstall-setuid"

      # ---- Systemd / udev / python (not on OHOS) ----
      args << "--without-systemd"
      args << "--without-udev"
      args << "--without-python"
    end

    system "./configure", *args, *std_configure_args

    install_args = []
    install_args << "LDFLAGS=-lm" if OS.linux?
    system "make", "install", *install_args
  end

  def caveats
    if OS.linux?
      <<~EOS
        Some util-linux kernel-dependent components may not work if the
        kernel or hardware does not support them (e.g. /proc, /sys,
        /dev/rtc, PAM, etc.).
      EOS
    end
  end

  test do
    stat  = File.stat "/usr"
    owner = Etc.getpwuid(stat.uid).name
    group = Etc.getgrgid(stat.gid).name

    flags = ["x", "w", "r"] * 3
    perms = flags.each_with_index.reduce("") do |sum, (flag, index)|
      sum.insert 0, (stat.mode.nobits?(2 ** index) ? "-" : flag)
    end

    out = shell_output("#{bin}/namei -lx /usr").split("\n").last.split
    assert_equal ["d#{perms}", owner, group, "usr"], out
  end
end
