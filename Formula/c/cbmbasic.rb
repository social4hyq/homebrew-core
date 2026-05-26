class Cbmbasic < Formula
  desc "Commodore BASIC V2 as a scripting language"
  homepage "https://github.com/mist64/cbmbasic"
  url "https://downloads.sourceforge.net/project/cbmbasic/cbmbasic/1.0/cbmbasic-1.0.tgz"
  sha256 "2735dedf3f9ad93fa947ad0fb7f54acd8e84ea61794d786776029c66faf64b04"
  license "BSD-2-Clause"
  head "https://github.com/mist64/cbmbasic.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c5f05778d6ea5856b6cc51094534a595b9c243e84f192790cf96cce202354f2"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `RAM'; cbmbasic.o:(.bss+0x10): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "make", "CFLAGS=#{ENV.cflags}", "LDFLAGS=#{ENV.ldflags}"
    bin.install "cbmbasic"
  end

  test do
    assert_match(/READY.\r\n 1/, pipe_output(bin/"cbmbasic", "PRINT 1\n", 0))
  end
end
