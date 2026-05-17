class Enca < Formula
  desc "Charset analyzer and converter"
  homepage "https://cihar.com/software/enca/"
  url "https://github.com/Project-OSS-Revival/enca/releases/download/1.22/enca-1.22.tar.xz"
  sha256 "95a70dd21198e6427d77a1d79721f4f87dd8bd07fdefe71a2062c6f41eee39da"
  license "GPL-2.0-only"
  head "https://github.com/Project-OSS-Revival/enca.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f95d648c1b22e9ea088fab1085558e6856f98db41d6dde209686adfb3db9b3f"
  end

  def install
    ENV.append "LIBS", "-liconv" if OS.mac?

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    enca = "#{bin}/enca --language=none"
    assert_match "ASCII", pipe_output(enca, "Testing...")
    ucs2_text = pipe_output("#{enca} --convert-to=UTF-16", "Testing...")
    assert_match "UCS-2", pipe_output(enca, ucs2_text)
  end
end
