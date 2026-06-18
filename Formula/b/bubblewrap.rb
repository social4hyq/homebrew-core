class Bubblewrap < Formula
  desc "Unprivileged sandboxing tool for Linux"
  homepage "https://github.com/containers/bubblewrap"
  url "https://github.com/containers/bubblewrap/releases/download/v0.11.2/bubblewrap-0.11.2.tar.xz"
  sha256 "69abc30005d2186baf7737feacd8da35633b93cf5af38838ecff17c5f8e924f6"
  license "LGPL-2.0-or-later"
  head "https://github.com/containers/bubblewrap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b4304e6740cd214616e116bceac433132f632a6f5515d533aa258bb17c6ce58"
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
