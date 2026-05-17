class Moreutils < Formula
  desc "Collection of tools that nobody wrote when UNIX was young"
  homepage "https://joeyh.name/code/moreutils/"
  url "https://git.joeyh.name/index.cgi/moreutils.git/snapshot/moreutils-0.70.tar.gz"
  sha256 "f2bf46d410ba567cc8d01507e94916994e48742722e690dc498fab59f5250132"
  license all_of: [
    "GPL-2.0-or-later",
    { any_of: ["GPL-2.0-only", "Artistic-2.0"] },
  ]
  head "https://git.joeyh.name/git/moreutils.git", branch: "master"

  livecheck do
    url :head
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56df004df813535b01f15813b4078bc1adceb7a04104244a5660581ce2b3bad2"
  end

  depends_on "docbook-xsl" => :build

  uses_from_macos "libxml2" => :build
  uses_from_macos "libxslt" => :build

  uses_from_macos "perl"

  conflicts_with "parallel", because: "both install a `parallel` executable"
  conflicts_with "pwntools", because: "both install an `errno` executable"
  conflicts_with "sponge", because: "both install a `sponge` executable"
  conflicts_with "task-spooler", because: "both install a `ts` executable"

  resource "Time::Duration" do
    url "https://cpan.metacpan.org/authors/id/N/NE/NEILB/Time-Duration-1.21.tar.gz"
    sha256 "fe340eba8765f9263694674e5dff14833443e19865e5ff427bbd79b7b5f8a9b8"
  end

  resource "IPC::Run" do
    url "https://cpan.metacpan.org/authors/id/T/TO/TODDR/IPC-Run-20231003.0.tar.gz"
    sha256 "eb25bbdf5913d291797ef1bfe998f15130b455d3ed02aacde6856f0b25e4fe57"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    resource("Time::Duration").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}", "--skipdeps"
      system "make", "install"
    end

    resource("IPC::Run").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make", "install"
    end

    inreplace "Makefile" do |s|
      s.gsub! "/usr/share/xml/docbook/stylesheet/docbook-xsl",
              "#{Formula["docbook-xsl"].opt_prefix}/docbook-xsl"
    end
    # Find our docbook catalog
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "make", "all"
    system "make", "install", "PREFIX=#{prefix}"
    bin.env_script_all_files(libexec/"bin", PERL5LIB: ENV["PERL5LIB"])
  end

  test do
    pipe_output("#{bin}/isutf8", "hello", 0)
    pipe_output("#{bin}/isutf8", "\xca\xc0\xbd\xe7", 1)
  end
end
