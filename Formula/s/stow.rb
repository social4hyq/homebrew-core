class Stow < Formula
  desc "Organize software neatly under a single directory tree (e.g. /usr/local)"
  homepage "https://www.gnu.org/software/stow/"
  url "https://ftpmirror.gnu.org/gnu/stow/stow-2.4.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz"
  sha256 "2a671e75fc207303bfe86a9a7223169c7669df0a8108ebdf1a7fe8cd2b88780b"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80e80b7d097f97839e6d15a46fc6ef7c52aa828870281f4c519ce605e6a8c5c7"
  end

  uses_from_macos "perl"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test").mkpath
    system bin/"stow", "-nvS", "test"
  end
end
