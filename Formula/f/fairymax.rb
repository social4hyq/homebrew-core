class Fairymax < Formula
  desc "AI for playing Chess variants"
  homepage "https://www.chessvariants.com/index/msdisplay.php?itemid=MSfairy-max"
  url "https://deb.debian.org/debian/pool/main/f/fairymax/fairymax_5.0b.orig.tar.gz"
  sha256 "3e36ba168aa10179225f8dd6953d1c39c4cd4526572765b2e9c77717efe3e52f"
  license :public_domain

  livecheck do
    skip "No longer developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d5ac76bef086e85c12dd10f42e0a8cc43e1275ca5d71329bc5d640ccf9d635c"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    system "make", "install", "prefix=#{prefix}", "CC=#{ENV.cc}"
  end

  test do
    (testpath/"test").write <<~EOS
      hint
      quit
    EOS
    refute_match(/piece-description file .* not found/, shell_output("#{bin}/fairymax < test"))
  end
end
