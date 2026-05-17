class Afio < Formula
  desc "Creates cpio-format archives"
  homepage "https://github.com/kholtman/afio"
  url "https://github.com/kholtman/afio/archive/refs/tags/v2.5.2.tar.gz"
  sha256 "c64ca14109df547e25702c9f3a9ca877881cd4bf38dcbe90fbd09c8d294f42b9"
  # See afio_license_issues_v5.txt
  license :cannot_represent
  head "https://github.com/kholtman/afio.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d337d6d697bf8c8ad943503e6bf00962d3174ae705e173b418867ee4edf1ebe"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "make", "DESTDIR=#{prefix}"
    bin.install "afio"
    man1.install "afio.1"

    prefix.install "ANNOUNCE-2.5.1" => "ANNOUNCE"
    prefix.install %w[INSTALLATION SCRIPTS]
    share.install Dir["script*"]
  end

  test do
    path = testpath/"test"
    path.write "homebrew"
    pipe_output("#{bin}/afio -o archive", "test\n", 0)

    system bin/"afio", "-r", "archive"
    path.unlink

    system bin/"afio", "-t", "archive"
    system bin/"afio", "-i", "archive"
    assert_equal "homebrew", path.read.chomp
  end
end
