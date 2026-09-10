class Xmlto < Formula
  desc "Convert XML to another format (based on XSL or other tools)"
  homepage "https://pagure.io/xmlto/"
  url "http://ftp.debian.org/debian/pool/main/x/xmlto/xmlto_0.0.29.orig.tar.bz2"
  sha256 "6000d8e8f0f9040426c4f85d7ad86789bc88d4aeaef585c4d4110adb0b214f21"
  license "GPL-2.0-or-later"
  revision 2

  livecheck do
    url "https://pagure.io/xmlto.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "85c2a920eac8718dacc05a84e27e9f04e26c80190d63611114030d82a802a158"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gnu-getopt" => :build

  depends_on "docbook"
  depends_on "docbook-xsl"
  depends_on "bash"

  uses_from_macos "libxslt"

  on_macos do
    # Doesn't strictly depend on GNU getopt, but macOS system getopt(1)
    # does not support longopts in the optstring, so use GNU getopt.
    depends_on "gnu-getopt"
  end

  def install
    # GNU getopt is keg-only, so point configure to it
    ENV["GETOPT"] = Formula["gnu-getopt"].opt_bin/"getopt" if OS.mac?
    # Find our docbook catalog
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    ENV.deparallelize
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    # Fix shebang and BASH variable: ensure brew bash is used regardless of what configure detected
    inreplace bin/"xmlto" do |s|
      s.gsub!(/^#!.*\/bash/, "#!#{Formula["bash"].opt_bin}/bash")
      s.gsub!(/^BASH=.*\/bash/, "BASH=#{Formula["bash"].opt_bin}/bash")
    end
  end

  test do
    (testpath/"test").write <<~EOS
      <?xmlif if foo='bar'?>
      Passing test.
      <?xmlif fi?>
    EOS
    assert_equal "Passing test.", pipe_output("#{bin}/xmlif foo=bar", (testpath/"test").read).strip
  end
end
