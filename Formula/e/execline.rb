class Execline < Formula
  desc "Interpreter-less scripting language"
  homepage "https://skarnet.org/software/execline/"
  url "https://skarnet.org/software/execline/execline-2.9.9.2.tar.gz"
  sha256 "908ed4db3a6b3a23a205d8fd4cf2a71089156f2aeae0f54656045aafad2dee32"
  license "ISC"
  head "git://git.skarnet.org/execline", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "43f1d05a1a6967d0ec7251e72d8197e467b3d119bd1328add18679c8584f77d1"
  end

  depends_on "pkgconf" => :build
  depends_on "skalibs"

  def install
    args = %W[
      --disable-silent-rules
      --enable-shared
      --enable-pkgconfig
      --with-pkgconfig=#{Formula["pkgconf"].opt_bin}/pkg-config
      --with-sysdeps=#{Formula["skalibs"].opt_lib}/skalibs/sysdeps
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.eb").write <<~EOS
      foreground
      {
        sleep 1
      }
      "echo"
      "Homebrew"
    EOS
    assert_match "Homebrew", shell_output("#{bin}/execlineb test.eb")
  end
end
