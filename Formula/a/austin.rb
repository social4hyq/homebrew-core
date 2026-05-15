class Austin < Formula
  desc "Python frame stack sampler for CPython"
  homepage "https://github.com/P403n1x87/austin"
  url "https://github.com/P403n1x87/austin/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "1a857d4590092cd8f7fc110cd83c31311dde03113a5dc4cb93c4eb31e5c8f884"
  license "GPL-3.0-or-later"
  head "https://github.com/P403n1x87/austin.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e77c73173b97f4a7e904f8fc027c447783c18099d147a96d9647068f98ca3dd"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "python" => :test

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make"
    system "make", "install"
    man1.install "src/austin.1"
  end

  test do
    command = "#{bin}/austin -o samples.mojo -i 1ms python3 -c 'from time import sleep; sleep(1)' 2>&1"
    if OS.mac?
      assert_match "Insufficient permissions. Austin requires the use of sudo", shell_output(command, 2)
    else
      assert_match "Sampling Statistics", shell_output(command)
    end
    assert_equal "austin #{version}", shell_output("#{bin}/austin --version").chomp
  end
end
