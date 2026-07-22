class Fswatch < Formula
  desc "Monitor a directory for changes and run a shell command"
  homepage "https://github.com/emcrisostomo/fswatch"
  url "https://github.com/emcrisostomo/fswatch/releases/download/1.22.0/fswatch-1.22.0.tar.gz"
  sha256 "fa6e2becba0a629964b466b39c5997e72d8a6da40d82b88190aae7359065c758"
  license all_of: ["GPL-3.0-or-later", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c5f232c4008a49cf6bffede7c998995b79f2e4ca680245bd0df9ca45a1b3d41"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"fswatch", "-h"
  end
end
