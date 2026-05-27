class Lifelines < Formula
  desc "Text-based genealogy software"
  homepage "https://lifelines.github.io/lifelines/"
  url "https://github.com/lifelines/lifelines/releases/download/3.1.1/lifelines-3.1.1.tar.gz"
  sha256 "083007f81e406fce15931e5a29a7ba0380ef0b3b9c61d5eb5228ad378c7f332d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b053e83ad1fa334018b80591c1fa56e59d8434e9b26c026b7c72b65483bb72ca"
  end

  uses_from_macos "bison" => :build
  uses_from_macos "ncurses"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/llines --version")
  end
end
