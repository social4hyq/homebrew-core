class Mp3check < Formula
  desc "Tool to check mp3 files for consistency"
  homepage "https://code.google.com/archive/p/mp3check/"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mp3check/mp3check-0.8.7.tgz"
  sha256 "27d976ad8495671e9b9ce3c02e70cb834d962b6fdf1a7d437bb0e85454acdd0e"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ce91d29907ffe78cb3050ae55fe77a099146579dba143739f62a4b70fb0a30f"
  end

  # Workaround: salsa.debian.org blocks CI server IPs.
  # Fetch the full debian.tar.xz from CDN instead to extract the GCC 9 patch.
  resource "debian-patches" do
    url "https://deb.debian.org/debian/pool/main/m/mp3check/mp3check_0.8.7-6.debian.tar.xz"
    sha256 "891b68a6d3b383ff25ba2d37e2c981aea55fb82785625c74b0f35ce53de9e470"
  end

  def install
    resource("debian-patches").stage do
      patch_file = "patches/fix_ftbfs_with_gcc_9"
      absolute_patch_path = File.expand_path(patch_file)
      system "patch", "-p1", "-i", absolute_patch_path, "-d", buildpath
    end

    ENV.deparallelize
    # The makefile's install target is kinda iffy, but there's
    # only one file to install so it's easier to do it ourselves
    system "make"
    bin.install "mp3check"
  end

  test do
    assert version.to_s, shell_output("#{bin}/mp3check --version")
  end
end
