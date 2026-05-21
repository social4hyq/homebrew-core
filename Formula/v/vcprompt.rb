class Vcprompt < Formula
  desc "Provide version control info in shell prompts"
  homepage "https://github.com/powerman/vcprompt"
  url "https://github.com/powerman/vcprompt/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "3db5ebad2e333d43b464b665c8d43b35156b0f144052f10c340a5c5007a6874d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02a9c663cd5744522cda4d4e1dbcc03b7c7c1b1e5b961f311794a2a8d7f0c419"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "sqlite"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "PREFIX=#{prefix}",
                   "MANDIR=#{man1}",
                   "install"
  end

  test do
    system bin/"vcprompt"
  end
end
