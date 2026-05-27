class Ii < Formula
  desc "Minimalist IRC client"
  homepage "https://tools.suckless.org/ii/"
  url "https://dl.suckless.org/tools/ii-2.0.tar.gz"
  sha256 "4f67afcd208c07939b88aadbf21497a702ad0a07f9b5a6ce861f9f39ffe5425b"
  license "MIT"
  head "https://git.suckless.org/ii/", using: :git, branch: "master"

  livecheck do
    url "https://dl.suckless.org/tools/"
    regex(/href=.*?ii[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "902d7d8097a001af8b14afaeb5d5b0aa0b33edb082c98ba732d7ee7534027322"
  end

  def install
    # macOS already provides strlcpy
    if OS.mac?
      inreplace "Makefile" do |s|
        s.gsub! "-D_DEFAULT_SOURCE -DNEED_STRLCPY", "-D_DEFAULT_SOURCE"
        s.gsub! "= strlcpy.o", "="
      end
    end

    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    port = free_port
    output = shell_output("#{bin}/ii -s localhost -p #{port} 2>&1", 1)
    assert_match "#{bin}/ii: could not connect to localhost:#{port}:", output.chomp
  end
end
