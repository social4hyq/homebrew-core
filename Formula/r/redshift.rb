class Redshift < Formula
  desc "Adjust color temperature of your screen according to your surroundings"
  homepage "https://github.com/jonls/redshift"
  url "https://github.com/jonls/redshift/releases/download/v1.12/redshift-1.12.tar.xz"
  sha256 "d2f8c5300e3ce2a84fe6584d2f1483aa9eadc668ab1951b2c2b8a03ece3a22ba"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b26da89b4de9007e9741f7b16010fa1d04679242b33e012ac5a0e3f00be42c3b"
  end

  head do
    url "https://github.com/jonls/redshift.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "gettext" => :build
  depends_on "intltool" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    args = %w[
      --disable-silent-rules
      --disable-geoclue
      --disable-geoclue2
      --with-systemduserunitdir=no
      --disable-gui
    ]

    if OS.mac?
      args << "--enable-corelocation"
      args << "--enable-quartz"
    end

    system "./bootstrap" if build.head?
    system "./configure", *args, *std_configure_args
    system "make", "install"
    pkgshare.install "redshift.conf.sample"
  end

  def caveats
    <<~EOS
      A sample .conf file has been installed to #{opt_pkgshare}.

      Please note redshift expects to read its configuration file from
      #{Dir.home}/.config/redshift/redshift.conf
    EOS
  end

  service do
    run opt_bin/"redshift"
    keep_alive true
    log_path File::NULL
    error_log_path File::NULL
  end

  test do
    system bin/"redshift", "-V"
  end
end
