# "File" is a reserved class name
class FileFormula < Formula
  desc "Utility to determine file types"
  homepage "https://darwinsys.com/file/"
  url "https://astron.com/pub/file/file-5.48.tar.gz"
  sha256 "ed14656883b23a364b4057c05595d93252da9bc473d30106519519d0da141283"
  license "BSD-2-Clause-Darwin"
  revision 1
  head "https://github.com/file/file.git", branch: "master"

  livecheck do
    url "https://astron.com/pub/file/"
    regex(/href=.*?file[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "73680c7b7e785ef35f29e247130ee15274937d8d21724f9f5e94efacb55502c4"
  end

  keg_only :provided_by_macos

  depends_on "libmagic"

  def install
    ENV.prepend "LDFLAGS", "-L#{Formula["libmagic"].opt_lib} -lmagic"

    system "./configure", *std_configure_args
    system "make", "install-exec", "file_DEPENDENCIES=", "file_LDADD=$(LDADD) -lm"
    system "make", "-C", "doc", "install-man1"
    rm_r lib
  end

  test do
    system bin/"file", test_fixtures("test.mp3")
  end
end
