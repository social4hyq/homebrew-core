class Fswatch < Formula
  desc "Monitor a directory for changes and run a shell command"
  homepage "https://github.com/emcrisostomo/fswatch"
  url "https://github.com/emcrisostomo/fswatch/releases/download/1.20.1/fswatch-1.20.1.tar.gz"
  sha256 "890c2d7c53f4e05726d891e6211e6700d5724d6a4d29055282bb849f6eaae227"
  license all_of: ["GPL-3.0-or-later", "Apache-2.0"]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ccbc1bd383466769d019405f163a7339175035fc53fa36add2017efdd1392b3"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"fswatch", "-h"
  end
end
