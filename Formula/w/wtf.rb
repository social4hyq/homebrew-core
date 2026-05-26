class Wtf < Formula
  desc "Translate common Internet acronyms"
  homepage "https://sourceforge.net/projects/bsdwtf/"
  url "https://downloads.sourceforge.net/project/bsdwtf/wtf-20230906.tar.gz"
  sha256 "ed9c1fa927fcd878cce955fb0bdc586876ee1ae234666be75c3bbd6e5b2a094b"
  license :public_domain

  livecheck do
    url :stable
    regex(%r{url=.*?/wtf[._-]v?(\d{6,8})\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c6e9bdcf55fca50a5b877101d2421a2494b892be2e174f4902096a7821252a9"
  end

  def install
    inreplace %w[wtf wtf.6], "/usr/share", share
    bin.install "wtf"
    man6.install "wtf.6"
    (share/"misc").install %w[acronyms acronyms.comp]
    (share/"misc").install "acronyms-o.real" => "acronyms-o"
  end

  test do
    assert_match "where's the food", shell_output("#{bin}/wtf wtf")
  end
end
