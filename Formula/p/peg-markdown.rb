class PegMarkdown < Formula
  desc "Markdown implementation based on a PEG grammar"
  homepage "https://github.com/jgm/peg-markdown"
  url "https://github.com/jgm/peg-markdown/archive/refs/tags/0.4.14.tar.gz"
  sha256 "111bc56058cfed11890af11bec7419e2f7ccec6b399bf05f8c55dae0a1712980"
  license any_of: ["GPL-2.0-or-later", "MIT"]
  revision 1
  head "https://github.com/jgm/peg-markdown.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72529ed0a2374185387f331810b5192bf9d06eae1deecac36f650ec3c08e89a2"
  end

  depends_on "pkgconf" => :build
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    # Workaround for arm64 linux. Upstream isn't maintained
    ENV.append_to_cflags "-fsigned-char" if OS.linux? && Hardware::CPU.arm?

    system "make"
    bin.install "markdown" => "peg-markdown"
  end

  test do
    assert_equal "<p><strong>Homebrew</strong></p>",
      pipe_output(bin/"peg-markdown", "**Homebrew**", 0).chomp
  end
end
