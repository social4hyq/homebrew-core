class Kore < Formula
  desc "Web application framework for writing web APIs in C"
  homepage "https://kore.io/"
  url "https://kore.io/releases/kore-4.2.3.tar.gz"
  sha256 "f9a9727af97441ae87ff9250e374b9fe3a32a3348b25cb50bd2b7de5ec7f5d82"
  license "ISC"
  head "https://github.com/jorisvink/kore.git", branch: "master"

  livecheck do
    url "https://kore.io/source"
    regex(/href=.*?kore[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f16bbd41f0cee64d9a01caf596800fe78417a4995cb4c9df3edfd835fb8eadc"
  end

  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    openssl = Formula["openssl@3"]

    # We modify Makefile variables to save OpenSSL paths which get used at runtime.
    # We don't directly override FEATURES_INC as Makefile uses 'FEATURES_INC+='.
    # This is not needed on macOS where the Makefile already saves pkg-config output.
    unless OS.mac?
      inreplace "Makefile", /^FEATURES_INC=$/, "FEATURES_INC=-I#{openssl.opt_include}"
      ENV["OPENSSL_PATH"] = openssl.opt_prefix
    end

    ENV.deparallelize { system "make", "PREFIX=#{prefix}", "TASKS=1" }
    system "make", "install", "PREFIX=#{prefix}"

    # Remove openssl cellar references, which breaks kore on openssl updates
    inreplace [pkgshare/"features", pkgshare/"linker"], openssl.prefix.realpath, openssl.opt_prefix if OS.mac?
  end

  test do
    system bin/"kodev", "create", "test"
    cd "test" do
      system bin/"kodev", "build"
      system bin/"kodev", "clean"
    end
  end
end
