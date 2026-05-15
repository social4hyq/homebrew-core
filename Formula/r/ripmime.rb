class Ripmime < Formula
  desc "Extract attachments out of MIME encoded email packages"
  homepage "https://pldaniels.com/ripmime/"
  url "https://github.com/inflex/ripMIME/archive/refs/tags/1.4.1.0.tar.gz"
  sha256 "6d551d6b65b4da6c6b8dfd05be8141026cc760ca1fb8a707b7bf96c199c9f52d"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93426fea14cab1545fc5398f40dc7ad2113bc2c59b2491000b298f4c196adf0c"
  end

  def install
    args = %W[
      CFLAGS=#{ENV.cflags}
    ]
    args << "LIBS=-liconv" if OS.mac?
    system "make", *args
    bin.install "ripmime"
    man1.install "ripmime.1"
  end

  test do
    (testpath/"message.eml").write <<~EOS
      MIME-Version: 1.0
      Subject: Test email
      To: example@example.org
      Content-Type: multipart/mixed;
            boundary="XXXXboundary text"

      --XXXXboundary text
      Content-Type: text/plain;
      name="attachment.txt"
      Content-Disposition: attachment;
      filename="attachment.txt"
      Content-Transfer-Encoding: base64

      SGVsbG8gZnJvbSBIb21lYnJldyEK

      --XXXXboundary text--
    EOS

    system bin/"ripmime", "-i", "message.eml"
    assert_equal "Hello from Homebrew!\n", (testpath/"attachment.txt").read
  end
end
