class Progress < Formula
  desc "Coreutils progress viewer"
  homepage "https://github.com/Xfennec/progress"
  url "https://github.com/Xfennec/progress/archive/refs/tags/v0.17.tar.gz"
  sha256 "ee9538fce98895dcf0d108087d3ee2e13f5c08ed94c983f0218a7a3d153b725d"
  license "GPL-3.0-or-later"
  head "https://github.com/Xfennec/progress.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7ce7f353940d36401cff8b04a18918f357b7870d9bf9baad8d9d4480e92778a9"
  end

  depends_on "pkgconf" => :build
  uses_from_macos "ncurses"

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    pid = spawn "/bin/dd", "if=/dev/urandom", "of=foo", "bs=512", "count=1048576"
    sleep 1
    begin
      assert_match "dd", shell_output(bin/"progress")
    ensure
      Process.kill 9, pid
      Process.wait pid
      rm "foo"
    end
  end
end
