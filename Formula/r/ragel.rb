class Ragel < Formula
  desc "State machine compiler"
  homepage "https://www.colm.net/open-source/ragel/"
  url "https://www.colm.net/files/ragel/ragel-6.10.tar.gz"
  sha256 "5f156edb65d20b856d638dd9ee2dfb43285914d9aa2b6ec779dac0270cd56c3f"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/Stable.*?href=.*?ragel[._-]v?(\d+(?:\.\d+)+)\.t/im)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b812eca5a701e8d371b25c3633074e2bc38a2dc9807c9873b4ec96ef1702bb14"
  end

  resource "pdf" do
    url "https://www.colm.net/files/ragel/ragel-guide-6.10.pdf"
    sha256 "efa9cf3163640e1340157c497db03feb4bc67d918fc34bc5b28b32e57e5d3a4e"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
    doc.install resource("pdf")
  end

  test do
    testfile = testpath/"rubytest.rl"
    testfile.write <<~EOS
      %%{
        machine homebrew_test;
        main := ( 'h' @ { puts "homebrew" }
                | 't' @ { puts "test" }
                )*;
      }%%
        data = 'ht'
        %% write data;
        %% write init;
        %% write exec;
    EOS
    system bin/"ragel", "-Rs", testfile
  end
end
