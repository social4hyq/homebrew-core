class Chkrootkit < Formula
  desc "Rootkit detector"
  homepage "https://www.chkrootkit.org/"
  url "ftp://ftp.chkrootkit.org/pub/seg/pac/chkrootkit-0.59.tar.gz"
  mirror "https://fossies.org/linux/misc/chkrootkit-0.59.tar.gz"
  sha256 "bd38f1d7f543a2aa6dd8c7ad6bb88df7c0d7dc101df57377dac24415cbc8c5ee"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?download[^>]*>chkrootkit v?(\d+(?:\.\d+)+[a-z]?)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ec34edbc93cb8bcc635148ea84e281fc8079159526e13bcb619fe808473b931"
  end

  def install
    ENV.deparallelize

    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}",
                   "STATIC=", "sense", "all"

    bin.install Dir[buildpath/"*"].select { |f| File.executable? f }
    doc.install %w[README README.chklastlog README.chkwtmp]
  end

  test do
    assert_equal "chkrootkit version #{version}",
                 shell_output("#{bin}/chkrootkit -V 2>&1", 1).strip
  end
end
