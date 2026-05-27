class Foremost < Formula
  desc "Console program to recover files based on their headers and footers"
  homepage "https://foremost.sourceforge.net/"
  url "https://foremost.sourceforge.net/pkg/foremost-1.5.7.tar.gz"
  sha256 "502054ef212e3d90b292e99c7f7ac91f89f024720cd5a7e7680c3d1901ef5f34"
  license :public_domain
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?foremost[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9f30fb5591a80141ffebc28e47450d49738ca9ebfa3e6e48642ed0b108464de"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `search_spec'; main.o:(.bss+0x8): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    inreplace "Makefile" do |s|
      s.gsub! "/usr/", "#{prefix}/"
      s.change_make_var! "RAW_CC", ENV.cc
      s.gsub!(/^RAW_FLAGS =/, "RAW_FLAGS = #{ENV.cflags}")
    end

    # Startup the command tries to look for the default config file in /usr/local,
    # move it to etc instead
    inreplace "config.c", "/usr/local/etc/", "#{etc}/"

    if OS.mac?
      system "make", "mac"
    else
      system "make"
    end

    bin.install "foremost"
    man8.install "foremost.8.gz"
    etc.install "foremost.conf" => "foremost.conf.default"
  end

  test do
    system bin/"foremost", "-V"
  end
end
