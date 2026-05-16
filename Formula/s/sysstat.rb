class Sysstat < Formula
  desc "Performance monitoring tools for Linux"
  homepage "https://sysstat.github.io/"
  url "https://github.com/sysstat/sysstat/archive/refs/tags/v12.7.9.tar.gz"
  sha256 "e48fc69401135dc08d2cd4ff58dbdbfce9b7485f76fc9049d97848e313c08dda"
  license "GPL-2.0-or-later"
  head "https://github.com/sysstat/sysstat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7b9f2fd9c6af11c1d2fd483ee218bf9f111363ced28df10cf71cf91b30770b0"
  end

  depends_on :linux

  def install
    system "./configure",
           "--disable-file-attr", # Fix install: cannot change ownership
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
