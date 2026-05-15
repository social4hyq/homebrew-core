class Hmmer < Formula
  desc "Build profile HMMs and scan against sequence databases"
  homepage "http://hmmer.org/"
  url "https://distfiles.macports.org/hmmer/hmmer-3.4.tar.gz"
  mirror "http://eddylab.org/software/hmmer/hmmer-3.4.tar.gz"
  sha256 "ca70d94fd0cf271bd7063423aabb116d42de533117343a9b27a65c17ff06fbf3"
  license "BSD-3-Clause"

  livecheck do
    url "http://eddylab.org/software/hmmer/"
    regex(/href=.*?hmmer[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "567d30a1e571a9f10417b8e1ba9bb4dccafb2cf1f679996b9db0211445ba2e79"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
    doc.install "Userguide.pdf", "tutorial"
  end

  test do
    assert_match "PF00069.17", shell_output("#{bin}/hmmstat #{doc}/tutorial/Pkinase.hmm")
  end
end
