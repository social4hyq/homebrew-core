class Distribution < Formula
  include Language::Python::Shebang

  desc "Create ASCII graphical histograms in the terminal"
  homepage "https://github.com/time-less-ness/distribution"
  url "https://github.com/time-less-ness/distribution/archive/refs/tags/1.3.tar.gz"
  sha256 "d7f2c9beeee15986d24d8068eb132c0a63c0bd9ace932e724cb38c1e6e54f95d"
  license "GPL-2.0-only"
  head "https://github.com/time-less-ness/distribution.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7fb7b4189a3838bea063fecfa10367c7e542cc5835aea24eb8d9f22626f17e13"
  end

  uses_from_macos "python"

  def install
    rewrite_shebang detected_python_shebang(use_python_from_path: true), "distribution.py"
    bin.install "distribution.py" => "distribution"
    doc.install "distributionrc", "screenshot.png"
  end

  test do
    assert_match "a|2 (66.67%)", pipe_output("#{bin}/distribution 2>/dev/null", "a\nb\na\n", 0)
  end
end
