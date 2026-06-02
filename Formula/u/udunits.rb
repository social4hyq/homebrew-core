class Udunits < Formula
  desc "Unidata unit conversion library"
  homepage "https://docs.unidata.ucar.edu/udunits/current/"
  url "https://downloads.unidata.ucar.edu/udunits/2.2.28/udunits-2.2.28.tar.gz"
  sha256 "590baec83161a3fd62c00efa66f6113cec8a7c461e3f61a5182167e0cc5d579e"
  license "UCAR"

  livecheck do
    url "https://downloads.unidata.ucar.edu/udunits/release_info.json"
    strategy :json do |json|
      json["releases"]&.map { |item| item["version"] }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7939637e100118b11abc71758e93962445c381d5dab4162c8b45d7da44ce869c"
  end

  head do
    url "https://github.com/Unidata/UDUNITS-2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "expat"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match(/1 kg = 1000 g/, shell_output("#{bin}/udunits2 -H kg -W g"))
  end
end
