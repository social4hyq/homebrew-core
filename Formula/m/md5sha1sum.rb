class Md5sha1sum < Formula
  desc "Hash utilities"
  homepage "http://microbrew.org/tools/md5sha1sum/"
  url "https://distfiles.macports.org/md5sha1sum/md5sha1sum-0.9.5.tar.gz"
  mirror "http://microbrew.org/tools/md5sha1sum/md5sha1sum-0.9.5.tar.gz"
  sha256 "2fe6b4846cb3e343ed4e361d1fd98fdca6e6bf88e0bba5b767b0fdc5b299f37b"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?md5sha1sum[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "374c8c8efa141b44e87a86fb01edd107e6d224ed8de2d1934069a5f7c049a584"
  end

  depends_on "openssl@4"

  on_sequoia :or_newer do
    keg_only :shadowed_by_macos, "macOS provides FreeBSD md5sum and sha1sum"
  end

  on_sonoma :or_older do
    conflicts_with "coreutils", because: "both install `md5sum` and `sha1sum` binaries"
  end

  on_linux do
    keg_only "Linux provides md5sum and sha1sum via GNU coreutils or BusyBox"
  end

  def install
    openssl = Formula["openssl@4"]
    ENV["SSLINCPATH"] = openssl.opt_include
    ENV["SSLLIBPATH"] = openssl.opt_lib

    system "./configure", "--prefix=#{prefix}"
    system "make"

    bin.install "md5sum"
    bin.install_symlink bin/"md5sum" => "sha1sum"
    bin.install_symlink bin/"md5sum" => "ripemd160sum"
  end

  test do
    (testpath/"file.txt").write("This is a test file with a known checksum")
    (testpath/"file.txt.sha1").write <<~EOS
      52623d47c33ad3fac30c4ca4775ca760b893b963  file.txt
    EOS
    system bin/"sha1sum", "--check", "file.txt.sha1"
  end
end
