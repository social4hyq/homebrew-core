class LibpthreadStubs < Formula
  desc "X.Org: pthread-stubs.pc"
  homepage "https://www.x.org/"
  url "https://xcb.freedesktop.org/dist/libpthread-stubs-0.5.tar.xz"
  sha256 "59da566decceba7c2a7970a4a03b48d9905f1262ff94410a649224e33d2442bc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8e7b5fdd78fb93db2941b5627a66b5798d7d91a3bcb984861693417c1e0a5a72"
  end

  depends_on "pkgconf"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_equal version.to_s, shell_output("pkgconf --modversion pthread-stubs").chomp
  end
end
