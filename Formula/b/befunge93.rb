class Befunge93 < Formula
  desc "Esoteric programming language"
  homepage "https://catseye.tc/article/Languages.md#befunge-93"
  url "https://catseye.tc/distfiles/befunge-93-2.25.zip"
  version "2.25"
  sha256 "93a11fbc98d559f2bf9d862b9ffd2932cbe7193236036169812eb8e72fd69b19"
  license "BSD-3-Clause"
  head "https://github.com/catseye/Befunge-93.git", branch: "master"

  livecheck do
    url "https://catseye.tc/distribution/Befunge-93_distribution"
    regex(/href=.*?befunge-93[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e190715bc7bb7ae8520c094aeadb26fd26d045420c8dd51640240ecc89ceaf99"
  end

  def install
    system "make"
    bin.install Dir["bin/bef*"]
  end

  test do
    (testpath/"test.bf").write '"dlroW olleH" ,,,,,,,,,,, @'
    assert_match "Hello World", shell_output("#{bin}/bef test.bf")
  end
end
