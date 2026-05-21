class Slugify < Formula
  desc "Convert filenames and directories to a web friendly format"
  homepage "https://github.com/benlinton/slugify"
  url "https://github.com/benlinton/slugify/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "f6873b062119d3eaa7d89254fc6e241debf074da02e3189f12e08b372af096e5"
  license "MIT"
  head "https://github.com/benlinton/slugify.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8fd6d28cf10ba652e8e2283222d1bf1a1c067520f51b240a9f8d5ac36b82e698"
  end

  def install
    bin.install "slugify"
    man1.install "slugify.1"
  end

  test do
    system bin/"slugify", "-n", "dry_run.txt"
  end
end
