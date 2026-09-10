class Rsync < Formula
  desc "Utility that provides fast incremental file transfer"
  homepage "https://rsync.samba.org/"
  url "https://github.com/RsyncProject/rsync/releases/download/v3.5.0/rsync-3.5.0.tar.gz"
  mirror "https://rsync.samba.org/ftp/rsync/rsync-3.5.0.tar.gz"
  sha256 "c7ffd1ef653e99540f661e47cb00b7f9cad1ee6b972399b16f93d672656e0d33"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d28af2fdbca73c9602326f47ac80625a70abc2433a30f6311b695afc610c1ec"
  end

  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "popt"
  depends_on "xxhash"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fix Linux sandbox compatibility
  patch do
    url "https://github.com/RsyncProject/rsync/commit/56e37eae666c7b0a52d29e9d1fb27325aaa8acf0.patch?full_index=1"
    sha256 "3bb2d6096b7fc2dcf550af022f32c00cf8fa186ad84596c574ddac29c38e23fb"
    type :unofficial
    resolves "https://github.com/RsyncProject/rsync/pull/1052"
  end

  def install
    args = %W[
      --with-rsyncd-conf=#{etc}/rsyncd.conf
      --with-included-popt=no
      --with-included-zlib=no
      --with-rrsync=yes
      --enable-ipv6
    ]

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    mkdir "a"
    mkdir "b"

    ["foo\n", "bar\n", "baz\n"].map.with_index do |s, i|
      (testpath/"a/#{i + 1}.txt").write s
    end

    system bin/"rsync", "-artv", testpath/"a/", testpath/"b/"

    (1..3).each do |i|
      assert_equal (testpath/"a/#{i}.txt").read, (testpath/"b/#{i}.txt").read
    end
  end
end
