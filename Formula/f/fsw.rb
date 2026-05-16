class Fsw < Formula
  desc "File change monitor with multiple backends"
  homepage "https://emcrisostomo.github.io/fsw/"
  url "https://github.com/emcrisostomo/fsw/releases/download/1.3.9/fsw-1.3.9.tar.gz"
  sha256 "9222f76f99ef9841dc937a8f23b529f635ad70b0f004b9dd4afb35c1b0d8f0ff"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6f0095fd7a9a2a14e358bace6f8623e255407fddbedb2ae09dfdd939295aa19"
  end

  # https://github.com/emcrisostomo/fsw/commit/36152c3d1ea3495420bdef809ddaff0fa972ab77
  deprecate! date: "2026-01-04", because: :unmaintained, replacement_formula: "fswatch"
  disable! date: "2027-01-04", because: :unmaintained, replacement_formula: "fswatch"

  def install
    ENV.append "CXXFLAGS", "-stdlib=libc++" if OS.mac?
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    io = IO.popen("#{bin}/fsw test")
    (testpath/"test").write("foo")
    sleep 2
    rm testpath/"test"
    sleep 2
    (testpath/"test").write("foo")
    sleep 2
    assert_equal File.expand_path("test"), io.gets.strip
  ensure
    Process.kill "INT", io.pid
    Process.wait io.pid
  end
end
