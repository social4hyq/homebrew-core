class Sysstat < Formula
  desc "Performance monitoring tools for Linux"
  homepage "https://sysstat.github.io/"
  url "https://github.com/sysstat/sysstat/archive/refs/tags/v12.8.0.tar.gz"
  sha256 "8aa2054c56c941ab30e1b14ad2e0076a7e6d6bf01f50e22d954885b8a7f9a679"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/sysstat/sysstat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "139e4d0e743e4b150ae13dd8bedc9568fcf018b8ea6c080b84fe907a50b132fe"
  end

  depends_on :linux

  def install
    system "./configure",
           "--disable-file-attr", # Fix install: cannot change ownership
           "--disable-automated-sar-reporting",
           "--prefix=#{prefix}",
           "conf_dir=#{etc}/sysconfig",
           "sa_dir=#{var}/log/sa"
    system "make", "install"
  end

  test do
    assert_match("PID", shell_output("#{bin}/pidstat"))
    assert_match("avg-cpu", shell_output("#{bin}/iostat"))
  end
end
