class GitIf < Formula
  desc "Glulx interpreter that is optimized for speed"
  homepage "https://ifarchive.org/indexes/if-archive/programming/glulx/interpreters/git/"
  url "https://ifarchive.org/if-archive/programming/glulx/interpreters/git/git-138.zip"
  version "1.3.8"
  sha256 "59de132505fdf2d212db569211c18ff0f1f4c1032c5370b95272d2c2b4e95c00"
  license "MIT"
  head "https://github.com/DavidKinder/Git.git", branch: "master"

  # The archive filename uses a dotless version, so we match the version from
  # the "Git 1.2.3" text after the archive link.
  livecheck do
    url :homepage
    regex(/href=.*?git[._-]v?\d+(?:\.\d+)*\.(?:t|zip).+?Git\s+v?(\d+(?:\.\d+)+)/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56f589c36679e86cea019c1af1d8634699f612e329af52410b354e9939ec9e0b"
  end

  depends_on "glktermw" => :build

  uses_from_macos "ncurses"

  def install
    glk = Formula["glktermw"]

    inreplace "Makefile", "GLK = cheapglk", "GLK = #{glk.name}"
    inreplace "Makefile", "GLKINCLUDEDIR = ../$(GLK)", "GLKINCLUDEDIR = #{glk.include}"
    inreplace "Makefile", "GLKLIBDIR = ../$(GLK)", "GLKLIBDIR = #{glk.lib}"
    inreplace "Makefile", /^OPTIONS = /, "OPTIONS = -DUSE_MMAP -DUSE_INLINE"

    system "make"
    bin.install "git" => "git-if"
  end

  test do
    assert pipe_output("#{bin}/git-if -v").start_with? "GlkTerm, library version"
  end
end
