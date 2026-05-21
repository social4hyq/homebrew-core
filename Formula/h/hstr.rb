class Hstr < Formula
  desc "Bash and zsh history suggest box"
  homepage "https://github.com/dvorka/hstr"
  url "https://github.com/dvorka/hstr/archive/refs/tags/v3.2.tar.gz"
  sha256 "bceab1cb3c3b636d9ff4dfbaf8b035530e76a36d948767ed1735c4e79d7473eb"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c92379b0de2149e81c7224a25f99c71bc66dcc841749b24e58bc0ae792f7968"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "readline"

  uses_from_macos "ncurses"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    ENV["HISTFILE"] = testpath/".hh_test"
    (testpath/".hh_test").write("test\n")
    assert_match "test", shell_output("#{bin}/hh -n").chomp
  end
end
