class Rzip < Formula
  desc "File compression tool (like gzip or bzip2)"
  homepage "https://rzip.samba.org/"
  url "https://rzip.samba.org/ftp/rzip/rzip-2.1.tar.gz"
  sha256 "4bb96f4d58ccf16749ed3f836957ce97dbcff3e3ee5fd50266229a48f89815b7"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://rzip.samba.org/ftp/rzip/"
    regex(/href=.*?rzip[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6068650a69656b142ab80ae246335087c900fc17625222a1dcf901d0ceaa26eb"
  end

  uses_from_macos "bzip2"

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"

    system "make", "install", "INSTALL_MAN=#{man}"

    bin.install_symlink "rzip" => "runzip"
    man1.install_symlink "rzip.1" => "runzip.1"
  end

  test do
    path = testpath/"data.txt"
    original_contents = "." * 1000
    path.write original_contents

    # compress: data.txt -> data.txt.rz
    system bin/"rzip", path
    refute_path_exists path

    # decompress: data.txt.rz -> data.txt
    system bin/"rzip", "-d", "#{path}.rz"
    assert_equal original_contents, path.read
  end
end
