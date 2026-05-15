class Docbook2x < Formula
  desc "Convert DocBook to UNIX manpages and GNU TeXinfo"
  homepage "https://docbook2x.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/docbook2x/docbook2x/0.8.8/docbook2X-0.8.8.tar.gz"
  sha256 "4077757d367a9d1b1427e8d5dfc3c49d993e90deabc6df23d05cfe9cd2fcdc45"
  license all_of: ["MIT", "DocBook-XML"]

  livecheck do
    url :stable
    regex(%r{url=.*?/docbook2X[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb2467d04577a7c9b7455c36e4f21a654951ea5df59b586b1388ee4d1665218c"
  end

  depends_on "docbook"

  uses_from_macos "expat"
  uses_from_macos "libxslt"
  uses_from_macos "perl"

  on_linux do
    resource "XML::NamespaceSupport" do
      url "https://cpan.metacpan.org/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz"
      sha256 "47e995859f8dd0413aa3f22d350c4a62da652e854267aa0586ae544ae2bae5ef"
    end
    resource "XML::Parser" do
      url "https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.44.tar.gz"
      sha256 "1ae9d07ee9c35326b3d9aad56eae71a6730a73a116b9fe9e8a4758b7cc033216"
    end
    resource "XML::SAX::Exception" do
      url "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz"
      sha256 "66cb355ba4ef47c10ca738bd35999723644386ac853abbeb5132841f5e8a2ad0"
    end
    resource "XML::SAX::ParserFactory" do
      url "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz"
      sha256 "4506c387043aa6a77b455f00f57409f3720aa7e553495ab2535263b4ed1ea12a"
    end
  end

  def install
    if OS.linux?
      ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"
      resources.each do |res|
        res.stage do
          system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
          system "make", "PERL5LIB=#{ENV["PERL5LIB"]}"
          system "make", "install"
        end
      end
    end

    inreplace "perl/db2x_xsltproc.pl", "http://docbook2x.sf.net/latest/xslt", "#{share}/docbook2X/xslt"
    inreplace "configure", "${prefix}", prefix
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"

    bin.env_script_all_files libexec/"bin", PERL5LIB: ENV["PERL5LIB"] if OS.linux?
  end

  test do
    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"
    (testpath/"brew.1.xml").write <<~XML
      <?xml version="1.0" encoding="ISO-8859-1"?>
      <!DOCTYPE refentry PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN"
                         "http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">
      <refentry id='brew1'>
      <refmeta>
        <refentrytitle>brew</refentrytitle>
        <manvolnum>1</manvolnum>
      </refmeta>
      <refnamediv>
        <refname>brew</refname>
        <refpurpose>The missing package manager for macOS</refpurpose>
      </refnamediv>
      </refentry>
    XML
    system bin/"docbook2man", testpath/"brew.1.xml"
    assert_path_exists testpath/"brew.1", "Failed to create man page!"
  end
end
