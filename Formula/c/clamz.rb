class Clamz < Formula
  desc "Download MP3 files from Amazon's music store"
  homepage "https://code.google.com/archive/p/clamz/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/clamz/clamz-0.5.tar.gz"
  sha256 "5a63f23f15dfa6c2af00ff9531ae9bfcca0facfe5b1aa82790964f050a09832b"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d820f6305af376b9709103744b17f78ad6d58386389322c9fdad64741626e8fb"
  end

  depends_on "pkgconf" => :build
  depends_on "libgcrypt"
  depends_on "libgpg-error"

  uses_from_macos "curl"
  uses_from_macos "expat"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/clamz --version 2>&1")
  end
end
