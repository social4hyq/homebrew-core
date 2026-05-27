class Procmail < Formula
  desc "Autonomous mail processor"
  homepage "https://github.com/BuGlessRB/procmail"
  url "https://github.com/BuGlessRB/procmail/archive/refs/tags/v3.24.tar.gz"
  sha256 "514ea433339783e95df9321e794771e4887b9823ac55fdb2469702cf69bd3989"
  license any_of: ["GPL-2.0-or-later", "Artistic-1.0-Perl"]
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a08a8854e0681f3681555c9a76e4f9881654d04b512c55df0a209956e4dc541"
  end

  # Apply open PR to fix build on modern Clang/GCC rather than disabling errors.
  # Same patch used by Fedora, Gentoo, MacPorts and NixOS.
  # PR ref: https://github.com/BuGlessRB/procmail/pull/7
  patch do
    url "https://github.com/BuGlessRB/procmail/commit/8cfd570fd14c8fb9983859767ab1851bfd064b64.patch?full_index=1"
    sha256 "2258b13da244b8ffbd242bc2a7e1e8c6129ab2aed4126e3394287bcafc1018e1"
  end

  def install
    # avoid issue from case-insensitive filesystem
    mv "INSTALL", "INSTALL.txt" if OS.mac?

    system "make", "install", "BASENAME=#{prefix}", "MANDIR=#{man}", "LOCKINGTEST=1"
  end

  test do
    path = testpath/"test.mail"
    path.write <<~EOS
      From alice@example.net Tue Sep 15 15:33:41 2015
      Date: Tue, 15 Sep 2015 15:33:41 +0200
      From: Alice <alice@example.net>
      To: Bob <bob@example.net>
      Subject: Test

      please ignore
    EOS
    assert_match "Subject: Test", shell_output("#{bin}/formail -X 'Subject' < #{path}")
    assert_match "please ignore", shell_output("#{bin}/formail -I '' < #{path}")
  end
end
