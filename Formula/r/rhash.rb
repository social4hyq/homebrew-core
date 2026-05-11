class Rhash < Formula
  desc "Utility for computing and verifying hash sums of files"
  homepage "https://sourceforge.net/projects/rhash/"
  url "https://downloads.sourceforge.net/project/rhash/rhash/1.4.6/rhash-1.4.6-src.tar.gz"
  sha256 "9f6019cfeeae8ace7067ad22da4e4f857bb2cfa6c2deaa2258f55b2227ec937a"
  license "0BSD"
  head "https://github.com/rhash/RHash.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c68881dcc980affb8694bba6aa3cba9e8213460190b544a40499d8e954670763"
  end

  def install
    # Exclude unrecognized options
    args = std_configure_args.reject { |s| s["--disable-dependency-tracking"] } + %W[
      --disable-lib-static
      --disable-gettext
      --sysconfdir=#{etc}
    ]

    system "./configure", *args
    system "make"
    # Avoid race during installation.
    ENV.deparallelize { system "make", "install" }
    system "make", "install-lib-headers", "install-pkg-config"
    lib.install_symlink (lib/shared_library("librhash", version.major.to_s).to_s) => shared_library("librhash")
  end

  test do
    (testpath/"test").write("test")
    (testpath/"test.sha1").write("a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 test")
    system bin/"rhash", "-c", "test.sha1"
  end
end
