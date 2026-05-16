class Cracklib < Formula
  desc "LibCrack password checking library"
  homepage "https://github.com/cracklib/cracklib"
  url "https://github.com/cracklib/cracklib/releases/download/v2.10.3/cracklib-2.10.3.tar.bz2"
  sha256 "f3dcb54725d5604523f54a137b378c0427c1a0be3e91cfb8650281a485d10dae"
  license "LGPL-2.1-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "117e1f446bb8f82132111bfb07e6128e487de22546c180e2c9847ea5fb92c22b"
  end

  head do
    url "https://github.com/cracklib/cracklib.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  resource "cracklib-words" do
    url "https://github.com/cracklib/cracklib/releases/download/v2.10.3/cracklib-words-2.10.3.bz2"
    sha256 "ec25ac4a474588c58d901715512d8902b276542b27b8dd197e9c2ad373739ec4"

    livecheck do
      formula :parent
    end
  end

  def install
    buildpath.install (buildpath/"src").children if build.head?
    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    system "./configure", "--disable-silent-rules",
                          "--sbindir=#{bin}",
                          "--without-python",
                          "--with-default-dict=#{var}/cracklib/cracklib-words",
                          *std_configure_args
    system "make", "install"

    share.install resource("cracklib-words")
  end

  def post_install
    (var/"cracklib").mkpath
    cp share/"cracklib-words-#{resource("cracklib-words").version}", var/"cracklib/cracklib-words"
    system "#{bin}/cracklib-packer < #{var}/cracklib/cracklib-words"
  end

  test do
    assert_match "password: it is based on a dictionary word", pipe_output(bin/"cracklib-check", "password", 0)
  end
end
