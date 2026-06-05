class Lesspipe < Formula
  desc "Input filter for the pager less"
  homepage "https://www-zeuthen.desy.de/~friebel/unix/lesspipe.html"
  url "https://github.com/wofr06/lesspipe/archive/refs/tags/v2.26.tar.gz"
  sha256 "bb50827715c7233e4d2deeffc5e499f6d792157994585d907f75d39f421e71ab"
  license all_of: [
    "GPL-2.0-only",
    "GPL-2.0-or-later", # sxw2txt
    "MIT", # code2color
    any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"], # vimcolor
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc37df4246bf7e78f88463e8cb54a8724aff2dba230a2492a22541cb33dc0492"
  end

  uses_from_macos "zsh" => :build # needed to guarantee installation of zsh completions
  uses_from_macos "perl"

  on_macos do
    depends_on "bash"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--shell=bash"
    system "make", "install"
  end

  def caveats
    <<~EOS
      add the following to your shell profile e.g. ~/.profile or ~/.zshrc:
        export LESSOPEN="|#{HOMEBREW_PREFIX}/bin/lesspipe.sh %s"
    EOS
  end

  test do
    touch "file1.txt"
    touch "file2.txt"
    system "tar", "-cvzf", "homebrew.tar.gz", "file1.txt", "file2.txt"

    assert_path_exists testpath/"homebrew.tar.gz"
    assert_match "file2.txt", pipe_output(bin/"archive_color", shell_output("tar -tvzf homebrew.tar.gz"))
  end
end
