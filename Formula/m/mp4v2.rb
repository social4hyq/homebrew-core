class Mp4v2 < Formula
  desc "Read, create, and modify MP4 files"
  homepage "https://mp4v2.org"
  url "https://github.com/enzo1982/mp4v2/releases/download/v2.1.3/mp4v2-2.1.3.tar.bz2"
  sha256 "033185c17bf3c5fdd94020c95f8325be2e5356558e3913c3d6547a85dd61f7f1"
  license "MPL-1.1"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36d7cc9dbbe0819cce2172a11b9b403240a23e13a4e383c4dfec7ad107608871"
  end

  conflicts_with "bento4",
    because: "both install `mp4extract` and `mp4info` binaries"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
    system "make", "install-man"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mp4art --version")
  end
end
