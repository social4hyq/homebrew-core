class Micro < Formula
  desc "Modern and intuitive terminal-based text editor"
  homepage "https://github.com/zyedidia/micro"
  url "https://github.com/zyedidia/micro.git",
      tag:      "v2.0.15",
      revision: "6a62575bcfdf4965f187eedafceb3400316e612b"
  license "MIT"
  head "https://github.com/zyedidia/micro.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "781e07f0faa38491e5fe5e10be2572d2bf9b9f74dcafb8bf35c82e559fe0c9a7"
  end

  depends_on "go" => :build

  def install
    system "make", "build-tags"
    bin.install "micro"
    man1.install "assets/packaging/micro.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/micro -version")
  end
end
