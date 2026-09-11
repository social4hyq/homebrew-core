class LinuxPam < Formula
  desc "Pluggable Authentication Modules for Linux"
  homepage "https://github.com/linux-pam/linux-pam"
  url "https://github.com/linux-pam/linux-pam/releases/download/v1.7.2/Linux-PAM-1.7.2.tar.xz"
  sha256 "3d86b6383fb5fd9eb9578d2cd47d92801191f4bf3f9bc61419bfefc8aa1e531a"
  license any_of: ["BSD-3-Clause", "GPL-1.0-only"]
  revision 1
  head "https://github.com/linux-pam/linux-pam.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "04a80df655d98f48fb6947dfb51cce8e8142caf7c79887c99ab6c52ecd920df8"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libnsl"
  depends_on "libtirpc"
  depends_on "libxcrypt"
  depends_on "gettext"
  depends_on :linux

  def install
    ENV.append "CFLAGS", "-Dgetspnam(x)=((void*)0)"
    ENV.append "CFLAGS", "-Dsetspent()=((void)0)"
    ENV.append "CFLAGS", "-Dendspent()=((void)0)"
    ENV.append "CFLAGS", "-Dfgetspent(x)=((void*)0)"
    ENV.append "CFLAGS", "-Dfgetpwent(x)=((void*)0)"
    ENV.append "CFLAGS", "-Dputspent(x,y)=0"
    ENV.append "LDFLAGS", "-lintl"

    system "meson", "setup", "build", "--sysconfdir=#{etc}", "-Dvendordir=#{pkgshare}/security",
"-Dsecuredir=#{lib}/security", "-Ddocs=disabled", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "Usage: #{sbin}/mkhomedir_helper <username>",
                 shell_output("#{sbin}/mkhomedir_helper 2>&1", 14)
  end
end
