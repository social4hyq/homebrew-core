class Distcc < Formula
  desc "Distributed compiler client and server"
  homepage "https://github.com/distcc/distcc/"
  license "GPL-2.0-or-later"
  revision 3

  stable do
    url "https://github.com/distcc/distcc/releases/download/v3.4/distcc-3.4.tar.gz"
    sha256 "2b99edda9dad9dbf283933a02eace6de7423fe5650daa4a728c950e5cd37bd7d"

    # TODO: Remove in the next release
    # https://github.com/distcc/distcc/commit/6d54352e209066418b4b268c7d2d266e05df1eb3
    resource "libiberty" do
      url "https://ftp.debian.org/debian/pool/main/libi/libiberty/libiberty_20250315.orig.tar.xz"
      sha256 "5b510b5e0918dcb00a748900103365a00411855f202089ff81dc5ef99d8beeaa"
    end

    # Python 3.10+ compatibility
    patch do
      url "https://github.com/distcc/distcc/commit/83e030a852daf1d4d8c906e46f86375d421b781e.patch?full_index=1"
      sha256 "d65097b7c13191e18699d3a9c7c9df5566bba100f8da84088aa4e49acf46b6a7"
    end

    # Switch from distutils to setuptools
    patch do
      url "https://github.com/distcc/distcc/commit/76873f8858bf5f32bda170fcdc1dfebb69de0e4b.patch?full_index=1"
      sha256 "611910551841854755b06d2cac1dc204f7aaf8c495a5efda83ae4a1ef477d588"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2533b67abca77506b4bdd81a9c132104e6996cbb369ca348aa96b107c4695d8e"
  end

  head do
    url "https://github.com/distcc/distcc.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "pkgconf" => :build
    depends_on "popt"
  end

  depends_on "python-setuptools" => :build
  depends_on "python@3.14"

  def install
    ENV["PYTHON"] = python3 = which("python3.14")
    site_packages = prefix/Language::Python.site_packages(python3)

    if build.stable?
      odie "Remove libiberty!" if version > "3.4"

      # While libiberty recommends that packages vendor libiberty into their own source,
      # distcc wants to have a package manager-installed version.
      # Rather than make a package for a floating package like this, let's just
      # make it a resource.
      resource("libiberty").stage do
        system "./libiberty/configure", "--prefix=#{buildpath}", "--enable-install-libiberty"
        system "make", "install"
      end
      ENV.append "CPPFLAGS", "-I#{buildpath}/include"
      ENV.append "LDFLAGS", "-L#{buildpath}/lib"
    end

    # Work around Homebrew's "prefix scheme" patch which causes non-pip installs
    # to incorrectly try to write into HOMEBREW_PREFIX/lib since Python 3.10.
    inreplace "Makefile.in", '--root="$$DESTDIR"', "--install-lib='#{site_packages}'"

    system "./autogen.sh" if build.head?
    system "./configure", *std_configure_args
    system "make", "install"
  end

  service do
    run [opt_bin/"distccd", "--allow=192.168.0.1/24"]
    keep_alive true
    working_dir opt_prefix
  end

  test do
    system bin/"distcc", "--version"

    (testpath/"Makefile").write <<~MAKE
      default:
      	@echo Homebrew
    MAKE
    assert_match "distcc hosts list does not contain any hosts", shell_output("#{bin}/pump make 2>&1", 1)

    # `pump make` timeout on linux runner and is not reproducible, so only run this test for macOS runners
    return unless OS.mac?

    ENV["DISTCC_POTENTIAL_HOSTS"] = "localhost"
    assert_match "Homebrew\n", shell_output("#{bin}/pump make")
  end
end
