class Jq < Formula
  desc "Lightweight and flexible command-line JSON processor"
  homepage "https://jqlang.github.io/jq/"
  url "https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz"
  sha256 "71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af"
  license "MIT"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^(?:jq[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a96de5f2cb3ed74d1241ede0491da7cd445c6ff5ffb77966987ecd3f1c56910"
  end

  head do
    url "https://github.com/jqlang/jq.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "oniguruma"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--disable-maintainer-mode"
    system "make", "install"
  end

  test do
    assert_equal "2\n", pipe_output("#{bin}/jq .bar", '{"foo":1, "bar":2}')
  end
end
