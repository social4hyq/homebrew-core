class Rats < Formula
  desc "Rough auditing tool for security"
  homepage "https://security.web.cern.ch/security/recommendations/en/codetools/rats.shtml"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rough-auditing-tool-for-security/rats-2.4.tgz"
  sha256 "2163ad111070542d941c23b98d3da231f13cf065f50f2e4ca40673996570776a"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0191a684900c561fb3b1e3a7084b5d4d30de704b374d298309a15658ffe82100"
  end

  uses_from_macos "expat"

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--mandir=#{man}",
                          "--infodir=#{info}"
    system "make", "install"
  end

  test do
    system bin/"rats"
  end
end
