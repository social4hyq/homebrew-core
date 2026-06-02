class Dict < Formula
  desc "Dictionary Server Protocol (RFC2229) client"
  homepage "https://dict.org/bin/Dict"
  url "https://downloads.sourceforge.net/project/dict/dictd/dictd-1.13.3/dictd-1.13.3.tar.gz"
  sha256 "192129dfb38fa723f48a9586c79c5198fc4904fec1757176917314dd073f1171"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c2cf072dcc17d8498a140538c361f5158481666184f90ce76c6e88b5e0e11b7c"
  end

  depends_on "libtool" => :build
  depends_on "libmaa"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Workaround for Xcode 14.3
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    ENV["ac_cv_search_yywrap"] = "yes"
    ENV["LIBTOOL"] = "glibtool"
    system "./configure", "--mandir=#{man}",
                          "--sysconfdir=#{etc}",
                          *std_configure_args
    system "make"
    system "make", "install"
    (prefix/"etc/dict.conf").write <<~EOS
      server localhost
      server dict.org
    EOS
  end

  test do
    assert_match "brewing or making beer.", shell_output("#{bin}/dict brew")
  end
end
