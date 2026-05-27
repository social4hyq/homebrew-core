class Gistit < Formula
  desc "Command-line utility for creating Gists"
  homepage "https://github.com/jrbasso/gistit"
  url "https://github.com/jrbasso/gistit/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "9d87cfdd6773ebbd3f6217b11d9ebcee862ee4db8be7e18a38ebb09634f76a78"
  license "MIT"
  head "https://github.com/jrbasso/gistit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb1710685894d2f421816ae6d2539730e6379dd54304717f67ed971886e13487"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "jansson"

  uses_from_macos "curl"

  def install
    system "./autogen.sh", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.txt").write "Hello"

    # Gist creation should fail due to lack of authentication token (401) or GitHub API limit (403)
    assert_match(/- code 40[13]/, shell_output("#{bin}/gistit -priv test.txt", 1))
  end
end
