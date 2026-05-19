class Enchive < Formula
  desc "Encrypted personal archives"
  homepage "https://github.com/skeeto/enchive"
  url "https://github.com/skeeto/enchive/releases/download/3.5/enchive-3.5.tar.xz"
  sha256 "cb867961149116443a85d3a64ef5963e3c399bdd377b326669bb566a3453bd06"
  license "Unlicense"
  head "https://github.com/skeeto/enchive.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "334f41819157392104777f791b67582da2e6868bbeb7fcf8553b8c3cbcbccfa4"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    sec_key = "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00" \
              "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" \
              "\x78\x06\x15\x09\xf7\x1f\xc4\x68\x95\x3e\xd4\xef\xfc\x22\x2f\x42" \
              "\xf3\x2b\x2f\x2b\x85\x2c\x71\x0b\x96\x80\x93\x70\xfb\xdd\x32\x71"
    pub_key = "\x8c\xb7\xc8\xf0\x2c\xec\xa6\xf4\x63\xbc\xde\xd1\x92\xb5\x72\xae" \
              "\x58\x58\xe5\x13\x3f\x6f\x60\x77\xbb\xe7\xa3\xe0\xc0\x5d\x46\x16"

    mkdir_p testpath/".config/enchive"
    (testpath/".config/enchive/enchive.pub").binwrite pub_key
    (testpath/".config/enchive/enchive.sec").binwrite sec_key

    plaintext = "Hello world!"
    ciphertext = pipe_output("#{bin}/enchive archive", plaintext)
    assert_equal plaintext, pipe_output("#{bin}/enchive extract", ciphertext)

    expected_fingerprint = "eb57253d-995bcf9d-743c1053-ed32723b"
    assert_equal expected_fingerprint, shell_output("#{bin}/enchive fingerprint").chomp
  end
end
