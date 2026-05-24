class Remake < Formula
  desc "GNU Make with improved error handling, tracing, and a debugger"
  homepage "https://bashdb.sourceforge.net/remake/"
  url "https://downloads.sourceforge.net/project/bashdb/remake/4.3%2Bdbg-1.6/remake-4.3%2Bdbg-1.6.tar.gz"
  version "4.3-1.6"
  sha256 "f6a0c6179cd92524ad5dd04787477c0cd45afb5822d977be93d083b810647b87"
  license "GPL-3.0-only"

  # We check the "remake" directory page because the bashdb project contains
  # various software and remake releases may be pushed out of the SourceForge
  # RSS feed.
  livecheck do
    url "https://sourceforge.net/projects/bashdb/files/remake/"
    regex(%r{href=.*?remake/v?(\d+(?:\.\d+)+(?:(?:%2Bdbg)?[._-]\d+(?:\.\d+)+)?)/?["' >]}i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match&.first&.sub(/%2Bdbg/i, "") }
    end
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d5b1927659985e8571b16be22a9c05f6dd46df8bfc44a04ca208e3557fa4e972"
  end

  depends_on "readline"

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    # Remove texinfo files for make to avoid conflict
    rm info.glob("make.info*")
  end

  test do
    (testpath/"Makefile").write <<~MAKE
      all:
      	echo "Nothing here, move along"
    MAKE
    system bin/"remake", "-x"
  end
end
