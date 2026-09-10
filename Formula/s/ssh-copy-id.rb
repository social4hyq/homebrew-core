class SshCopyId < Formula
  desc "Add a public key to a remote machine's authorized_keys file"
  homepage "https://www.openssh.com/"
  url "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.5p1.tar.gz"
  mirror "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.5p1.tar.gz"
  version "10.5p1"
  sha256 "d44d28a839ea9daf969cc69150fde59910b2b39361dad81a3bd6cbd19218db11"
  license "SSH-OpenSSH"
  revision 1
  head "https://github.com/openssh/openssh-portable.git", branch: "master"

  livecheck do
    formula "openssh"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f776a81a0d4f0671f7e762e5161876aaf47eeaab3734ca9f7a84556974aeb58"
  end

  keg_only :provided_by_macos

  def install
    bin.install "contrib/ssh-copy-id"
    man1.install "contrib/ssh-copy-id.1"
  end

  test do
    output = shell_output("#{bin}/ssh-copy-id -h 2>&1", 1)
    assert_match "identity_file", output
  end
end
