class Shunit2 < Formula
  desc "Unit testing framework for Bourne-based shell scripts"
  homepage "https://github.com/kward/shunit2"
  url "https://github.com/kward/shunit2/archive/refs/tags/v2.1.8.tar.gz"
  sha256 "b2fed28ba7282e4878640395284e43f08a029a6c27632df73267c8043c71b60c"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5a6859bd156b00eb8273695131cda0456803b4e47c605d1a9ead9336b6e6201"
  end

  def install
    bin.install "shunit2"
  end

  test do
    system bin/"shunit2"
  end
end
