class Scrypt < Formula
  desc "Encrypt and decrypt files using memory-hard password function"
  homepage "https://www.tarsnap.com/scrypt.html"
  url "https://www.tarsnap.com/scrypt/scrypt-1.3.3.tgz"
  sha256 "1c2710517e998eaac2e97db11f092e37139e69886b21a1b2661f64e130215ae9"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0b8da4bafaa4641686354bbd0ff9692bd81ac5e14a3742e4096c39789cc4fc9"
  end

  head do
    url "https://github.com/Tarsnap/scrypt.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "openssl@4"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    require "expect"
    require "pty"

    touch "homebrew.txt"
    PTY.spawn(bin/"scrypt", "enc", "homebrew.txt", "homebrew.txt.enc") do |r, w, _pid|
      r.expect "Please enter passphrase: "
      w.write "Testing\n"
      r.expect "Please confirm passphrase: "
      w.write "Testing\n"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    end

    assert_path_exists testpath/"homebrew.txt.enc"
  end
end
