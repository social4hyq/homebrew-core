class Minisign < Formula
  desc "Sign files & verify signatures. Works with signify in OpenBSD"
  homepage "https://jedisct1.github.io/minisign/"
  url "https://github.com/jedisct1/minisign/archive/refs/tags/0.12.tar.gz"
  sha256 "796dce1376f9bcb1a19ece729c075c47054364355fe0c0c1ebe5104d508c7db0"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c78a633dd64306652abd926b080826190937894608f125590a62af67ce85399"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libsodium"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    require "expect"
    require "pty"

    (testpath/"homebrew.txt").write "Hello World!"
    timeout = 5

    PTY.spawn(bin/"minisign", "-G") do |r, w, pid|
      refute_nil r.expect("Password: ", timeout), "Expected password input"
      w.write "Homebrew\n"
      refute_nil r.expect("Password (one more time): ", timeout), "Expected password confirmation input"
      w.write "Homebrew\n"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
    assert_path_exists testpath/"minisign.pub"
    assert_path_exists testpath/".minisign/minisign.key"

    PTY.spawn(bin/"minisign", "-Sm", "homebrew.txt") do |r, w, pid|
      refute_nil r.expect("Password: ", timeout), "Expected password input"
      w.write "Homebrew\n"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
    assert_path_exists testpath/"homebrew.txt.minisig"
  end
end
