class Fcrackzip < Formula
  desc "Zip password cracker"
  homepage "https://oldhome.schmorp.de/marc/fcrackzip.html"
  url "https://oldhome.schmorp.de/marc/data/fcrackzip-1.0.tar.gz"
  sha256 "4a58c8cb98177514ba17ee30d28d4927918bf0bdc3c94d260adfee44d2d43850"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://oldhome.schmorp.de/marc/data/"
    regex(/href=.*?fcrackzip[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b8793c8e3e340230226316cb735f4fb2ee0c9f20dadf55850d4f5dd392b8dcc"
  end

  uses_from_macos "zip" => :test

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
    # Avoid conflict with `unzip` on Linux and shadowing `/usr/bin/zipinfo` on macOS
    bin.install bin/"zipinfo" => "fcrackzipinfo"
  end

  test do
    (testpath/"secret").write "homebrew"
    system "zip", "-qe", "-P", "a", "secret.zip", "secret"
    assert_match "possible pw found: a ()",
                 shell_output("#{bin}/fcrackzip -c a -l 1 secret.zip").strip
  end
end
