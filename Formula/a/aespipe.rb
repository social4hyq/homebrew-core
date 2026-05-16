class Aespipe < Formula
  desc "AES encryption or decryption for pipes"
  homepage "https://loop-aes.sourceforge.net/"
  url "https://loop-aes.sourceforge.net/aespipe/aespipe-v2.4j.tar.bz2"
  sha256 "448fe1e58612c184951645ddd926fc5bdb64fc4f2f828c766c82aa1127e9a3e2"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://loop-aes.sourceforge.net/aespipe/"
    regex(/href=.*?aespipe[._-]v?(\d+(?:\.\d+)+[a-z]?)\.t/i)
    strategy :page_match
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72ca8de67d273859a9ca795831c8b2f632a0826a4533c105981cfd7831e37790"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"secret").write "thisismysecrethomebrewdonttellitplease"
    msg = "Hello this is Homebrew"
    encrypted = pipe_output("#{bin}/aespipe -P secret", msg, 0)
    decrypted = pipe_output("#{bin}/aespipe -P secret -d", encrypted, 0)
    assert_equal msg, decrypted.gsub(/\x0+$/, "")
  end
end
