class RpcsvcProto < Formula
  desc "Rpcsvc protocol definitions from glibc"
  homepage "https://github.com/thkukuk/rpcsvc-proto"
  url "https://github.com/thkukuk/rpcsvc-proto/releases/download/v1.4.4/rpcsvc-proto-1.4.4.tar.xz"
  sha256 "81c3aa27edb5d8a18ef027081ebb984234d5b5860c65bd99d4ac8f03145a558b"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "947309297c44cd7a762ee000dc5709aead186cdf5f65713a2368eab8e0702a3b"
  end

  keg_only :shadowed_by_macos

  on_macos do
    depends_on "gettext"
  end

  def install
    inreplace "rpcgen/rpc_main.c", "rindex", "strrchr"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "nettype", shell_output("#{bin}/rpcgen 2>&1", 1)

    (testpath/"msg.x").write <<~EOS
      program MESSAGEPROG {
        version PRINTMESSAGEVERS {
          int PRINTMESSAGE(string) = 1;
        } = 1;
      } = 0x20000001;
    EOS
    system bin/"rpcgen", "msg.x"
    assert_path_exists "msg_svc.c"
  end
end
