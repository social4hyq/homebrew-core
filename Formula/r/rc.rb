class Rc < Formula
  desc "Implementation of the AT&T Plan 9 shell"
  homepage "https://github.com/rakitzis/rc"
  url "https://web.archive.org/web/20200227085442/static.tobold.org/rc/rc-1.7.4.tar.gz"
  mirror "https://src.fedoraproject.org/repo/extras/rc/rc-1.7.4.tar.gz/f99732d7a8be3f15f81e99c3af46dc95/rc-1.7.4.tar.gz"
  sha256 "5ed26334dd0c1a616248b15ad7c90ca678ae3066fa02c5ddd0e6936f9af9bfd8"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bafbf2c8f52acfeb5e348aceccc87ea98fc904236a7447de39adcdf3e75ea5ee"
  end

  deprecate! date: "2024-06-10", because: :repo_removed
  disable! date: "2025-06-21", because: :repo_removed

  uses_from_macos "libedit"

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--mandir=#{man}",
                          "--with-edit=edit"
    system "make"
    system "make", "install"
  end

  test do
    assert_equal "Hello!", shell_output("#{bin}/rc -c 'echo Hello!'").chomp
  end
end
