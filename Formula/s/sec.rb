class Sec < Formula
  desc "Event correlation tool for event processing of various kinds"
  homepage "https://simple-evcorr.sourceforge.net/"
  url "https://github.com/simple-evcorr/sec/releases/download/2.9.4/sec-2.9.4.tar.gz"
  sha256 "77fd945980d15ca07f94a9cad6484677f5d3fe8ded5da12ec2c0c444ae7b0994"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2246e8fb857f92fd4de85cc9e948fb9d3cabb6d17b1f91d697ba1b5eba7415b4"
  end

  def install
    bin.install "sec"
    man1.install "sec.man" => "sec.1"
  end

  test do
    system bin/"sec", "--version"
  end
end
