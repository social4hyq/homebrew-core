class Bubblewrap < Formula
  desc "Unprivileged sandboxing tool for Linux"
  homepage "https://github.com/containers/bubblewrap"
  url "https://github.com/containers/bubblewrap/releases/download/v0.12.0/bubblewrap-0.12.0.tar.xz"
  sha256 "9760d007363e3abba7c747489910f9f82d9fca53ba3bd3282e396fa3c97a3314"
  license "LGPL-2.0-or-later"
  revision 1
  head "https://github.com/containers/bubblewrap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7761758c2e865515fdd1e931c6571d9ce01b522c089c96747e09b80f1d0a2927"
  end

  depends_on "docbook-xsl" => :build
  depends_on "libxslt" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "strace" => :test
  depends_on "libcap"
  depends_on :linux

  def install
    # get_current_dir_name() is a GNU extension, not available on musl.
    # Use the POSIX equivalent getcwd(NULL, 0) instead.
    inreplace "bubblewrap.c", "get_current_dir_name ()", "getcwd(NULL, 0)"
    # PATH_MAX requires an explicit <limits.h> include; musl-based libcs do not
    # pull it in transitively via other headers like glibc does.
    inreplace "bubblewrap.c", "#include <sched.h>", "#include <sched.h>\n#include <limits.h>"
    inreplace "safe_openat.c", "#include <sys/syscall.h>", "#include <sys/syscall.h>\n#include <limits.h>"
    # Meson modifies RPATHs during install but cannot handle paths injected by
    # our shim and results in a non-relocatable binary. Instead, we can remove
    # the shim RPATHs and pass them via the available meson option.
    args = %W[
      -Dinstall_rpath=#{ENV.delete("HOMEBREW_RPATH_PATHS")}
      -Dselinux=disabled
    ]
    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "bubblewrap", "#{bin}/bwrap --version"
    assert_match "clone", shell_output("strace -e inject=clone:error=EPERM " \
                                       "#{bin}/bwrap --bind / / /bin/echo hi 2>&1", 1)
  end
end
