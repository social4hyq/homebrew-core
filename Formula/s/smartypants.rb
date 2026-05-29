class Smartypants < Formula
  desc "Typography prettifier"
  homepage "https://daringfireball.net/projects/smartypants/"
  url "https://daringfireball.net/projects/downloads/SmartyPants_1.5.1.zip"
  sha256 "2813a12d8dd23f091399195edd7965e130103e439e2a14f298b75b253616d531"
  license "BSD-3-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?SmartyPants[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "061b291a51b2047e59554fb2e297052ec9df1c7e8ed64cdb101e1a8f07f57882"
  end

  def install
    bin.install "SmartyPants.pl" => "smartypants"
  end

  test do
    assert_equal "&#8220;Give me a beer&#8221;, said Mike O&#8217;Connor",
      pipe_output(bin/"smartypants",
                  %q("Give me a beer", said Mike O'Connor), 0)
  end
end
