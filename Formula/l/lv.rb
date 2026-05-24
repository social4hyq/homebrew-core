class Lv < Formula
  desc "Powerful multi-lingual file viewer/grep"
  # The upstream homepage was "https://web.archive.org/web/20160310122517/www.ff.iij4u.or.jp/~nrt/lv/"
  homepage "https://salsa.debian.org/debian/lv"
  url "https://salsa.debian.org/debian/lv/-/archive/debian/4.51-10.1/lv-debian-4.51-10.1.tar.gz"
  version "4.51-10.1"
  sha256 "64c1efb7d66301625d3a46dd4b3abed45942b2686de335860bf24a37b01ea858"
  license "GPL-2.0-or-later"
  head "https://salsa.debian.org/debian/lv.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be1f6d64f2dee5eddbb34da18014bd5a3877cb3641d2e67cca0fc439dfc45365"
  end

  uses_from_macos "ncurses"

  on_linux do
    depends_on "gzip"
  end

  def install
    File.read("debian/patches/series").each_line do |line|
      line.chomp!
      system "patch", "-p1", "-i", "debian/patches/"+line
    end

    cd "build" do
      system "../src/configure", "--prefix=#{prefix}"
      system "make"
      bin.install "lv"
      bin.install_symlink "lv" => "lgrep"
    end

    man1.install "lv.1"
    (lib/"lv").install "lv.hlp"
  end

  test do
    system bin/"lv", "-V"
  end
end
