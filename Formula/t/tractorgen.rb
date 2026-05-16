class Tractorgen < Formula
  desc "Generates ASCII tractor art"
  homepage "https://vergenet.net/~conrad/software/tractorgen/"
  url "https://vergenet.net/~conrad/software/tractorgen/dl/tractorgen-0.31.7.tar.gz"
  sha256 "469917e1462c8c3585a328d035ac9f00515725301a682ada1edb3d72a5995a8f"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?tractorgen[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67f4f33111250c181fdc9c1995959aa59d0e3bbdc43e2d8b6c88f64d2cc2774e"
  end

  # Backport fix for error: call to undeclared function 'atoi'
  patch do
    url "https://github.com/kfish/tractorgen/commit/294162055ba4ab3a5a80a5ae1cfbdcbe92584239.patch?full_index=1"
    sha256 "1848b797ec759c1dfe97fe42cb20f5316b08b7b710fd1dba19b7443879af8dfb"
  end

  def install
    # Workaround for Xcode 14.3. Alternatively could autoreconf but that requires additional dependencies.
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    expected = <<~'EOS'.gsub(/^/, "     ") # needs to be indented five spaces
          r-
         _|
        / |_\_    \\
       |    |o|----\\
       |_______\_--_\\
      (O)_O_O_(O)    \\
    EOS
    assert_equal expected, shell_output("#{bin}/tractorgen 4")
  end
end
