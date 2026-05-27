class Fdclone < Formula
  desc "Console-based file manager"
  homepage "https://hp.vector.co.jp/authors/VA012337/soft/fd/"
  url "https://deb.debian.org/debian/pool/main/f/fdclone/fdclone_3.01j.orig.tar.gz"
  mirror "http://www.unixusers.net/src/fdclone/FD-3.01j.tar.gz"
  version "3.01j"
  sha256 "fe5bb67eb670dcdb1f7368698641c928523e2269b9bee3d13b3b77565d22a121"
  license :cannot_represent

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d1af23d734fe2ee40cf28f52e6782924fa564957e581703dbe6b3750219254dc"
  end

  # Upstream homepage is gone and doesn't build on macOS Sequoia and later
  deprecate! date: "2026-01-05", because: :repo_removed
  disable! date: "2027-01-05", because: :repo_removed

  depends_on maximum_macos: [:sonoma, :build]
  depends_on "nkf" => :build

  uses_from_macos "ncurses"

  conflicts_with "fd", because: "both install `fd` binaries"

  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/fdclone/3.01b.patch"
    sha256 "c4159db3052d7e4abec57ca719ff37f5acff626654ab4c1b513d7879dcd1eb78"
  end

  def install
    ENV.deparallelize
    system "make", "PREFIX=#{prefix}", "all"
    system "make", "MANTOP=#{man}", "install"

    %w[README FAQ HISTORY LICENSES TECHKNOW ToAdmin].each do |file|
      system "nkf", "-w", "--overwrite", file
      prefix.install "#{file}.eng" => file
      prefix.install file => "#{file}.ja"
    end

    pkgshare.install "_fdrc" => "fd2rc.dist"
  end

  def caveats
    <<~EOS
      To install the initial config file:
          install -c -m 0644 #{opt_pkgshare}/fd2rc.dist ~/.fd2rc
      To set application messages to Japanese, edit your .fd2rc:
          MESSAGELANG="ja"
    EOS
  end

  test do
    assert_match "Hello Homebrew", shell_output("#{bin}/fdsh -c \"echo Hello Homebrew\"")
  end
end
