class Phoon < Formula
  desc "Displays current or specified phase of the moon via ASCII art"
  homepage "https://www.acme.com/software/phoon/"
  url "https://www.acme.com/software/phoon/phoon_14Aug2014.tar.gz"
  version "20140814"
  sha256 "bad9b5e37ccaf76a10391cc1fa4aff9654e54814be652b443853706db18ad7c1"
  license "BSD-2-Clause"
  version_scheme 1

  livecheck do
    skip "No longer developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "713026cbd28cc5bc19db5aa6662263426dc1016699d066852f337611d0adba20"
  end

  def install
    system "make"
    bin.install "phoon"
    man1.install "phoon.1"
  end

  test do
    system bin/"phoon"
  end
end
