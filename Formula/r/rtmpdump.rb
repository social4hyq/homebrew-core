class Rtmpdump < Formula
  desc "Tool for downloading RTMP streaming media"
  homepage "https://rtmpdump.mplayerhq.hu/"
  url "https://ftp.debian.org/debian/pool/main/r/rtmpdump/rtmpdump_2.6.orig.tar.xz"
  sha256 "f88e141ea3e126574dce24dca364f209560e13097fbba9c7f6b2f47a9a167646"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  compatibility_version 1
  head "https://git.ffmpeg.org/rtmpdump.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79b94de8cc3f2459e2c51f0a35363c6b37fa834b1b36c1d8749144917ee83bf2"
  end

  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  conflicts_with "flvstreamer", because: "both install 'rtmpsrv', 'rtmpsuck' and 'streams' binary"

  def install
    ENV.deparallelize

    os = if OS.mac?
      "darwin"
    else
      "posix"
    end

    system "make", "CC=#{ENV.cc}",
                   "XCFLAGS=#{ENV.cflags}",
                   "XLDFLAGS=#{ENV.ldflags}",
                   "MANDIR=#{man}",
                   "SYS=#{os}",
                   "prefix=#{prefix}",
                   "sbindir=#{bin}",
                   "install"
  end

  test do
    system bin/"rtmpdump", "-h"
  end
end
