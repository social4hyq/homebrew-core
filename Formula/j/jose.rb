class Jose < Formula
  desc "C-language implementation of Javascript Object Signing and Encryption"
  homepage "https://github.com/latchset/jose"
  url "https://github.com/latchset/jose/releases/download/v15/jose-15.tar.xz"
  sha256 "1d055c445392aa48d709ecd6e56220384ae2b480496e270818bddf1f219c8659"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2fb034e5dda3b75ced534d3176dfb77c36d18634f3b5b1a147c1aeb8ee8b933b"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "jansson"
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    system bin/"jose", "jwk", "gen", "-i", '{"alg": "A128GCM"}', "-o", "oct.jwk"
    system bin/"jose", "jwk", "gen", "-i", '{"alg": "RSA1_5"}', "-o", "rsa.jwk"
    system bin/"jose", "jwk", "pub", "-i", "rsa.jwk", "-o", "rsa.pub.jwk"
    system "echo hi | #{bin}/jose jwe enc -I - -k rsa.pub.jwk -o msg.jwe"
    output = shell_output("#{bin}/jose jwe dec -i msg.jwe -k rsa.jwk 2>&1")
    assert_equal "hi", output.chomp
    output = shell_output("#{bin}/jose jwe dec -i msg.jwe -k oct.jwk 2>&1", 1)
    assert_equal "Unwrapping failed!", output.chomp
  end
end
