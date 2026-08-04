class FdkAacEncoder < Formula
  desc "Command-line encoder frontend for libfdk-aac"
  homepage "https://github.com/nu774/fdkaac"
  url "https://github.com/nu774/fdkaac/archive/refs/tags/v1.0.9.tar.gz"
  sha256 "be6de0851c447d132e9bff0141068ee6fec6d37e21973ea9304480c68178058b"
  license "Zlib"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ecef08be2b4e992e329dd92a91f6caac9d7ed3dafb3dff20b8efbc26fe1e7d50"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "fdk-aac"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules",
                          "--mandir=#{man}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    # generate test tone pcm file
    sample_rate = 44100
    two_pi = Math::PI * 2

    num_samples = sample_rate
    frequency = 440.0
    max_amplitude = 0.2

    position_in_period = 0.0
    position_in_period_delta = frequency / sample_rate

    samples = [].fill(0.0, 0, num_samples)

    num_samples.times do |i|
      samples[i] = Math.sin(position_in_period * two_pi) * max_amplitude

      position_in_period += position_in_period_delta

      position_in_period -= 1.0 if position_in_period >= 1.0
    end

    samples.map! do |sample|
      (sample * 32767.0).round
    end

    (testpath/"tone.pcm").open("wb") do |f|
      f.syswrite(samples.flatten.pack("s*"))
    end

    system bin/"fdkaac", "-R", "--raw-channels", "1", "-m",
           "1", testpath/"tone.pcm", "--title", "Test Tone"
  end
end
