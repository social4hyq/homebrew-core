class Shmcat < Formula
  desc "Tool that dumps shared memory segments (System V and POSIX)"
  homepage "https://shmcat.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/shmcat/shmcat-1.9.tar.xz"
  sha256 "831f1671e737bed31de3721b861f3796461ebf3b05270cf4c938749120ca8e5b"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/shmcat[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cd9405482822916c083125bbb2db569b10e39805cdc7d994be3444fba847bcdb"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-ftok",
                          "--disable-nls"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shmcat --version")
  end
end
