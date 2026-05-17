class Flock < Formula
  desc "Lock file during command"
  homepage "https://github.com/discoteq/flock"
  url "https://github.com/discoteq/flock/releases/download/v0.4.0/flock-0.4.0.tar.xz"
  sha256 "01bbd497d168e9b7306f06794c57602da0f61ebd463a3210d63c1d8a0513c5cc"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fa33dc1c116eda4da28950ef971b606a7f2781f361b41c96f1afaec6a97d8d5b"
  end

  on_linux do
    conflicts_with "util-linux", because: "both install `flock` binaries"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    pid = spawn bin/"flock", "tmpfile", "sleep", "5"
    sleep 1
    assert_empty shell_output("#{bin}/flock --nonblock tmpfile true", 1)
  ensure
    Process.wait pid
  end
end
