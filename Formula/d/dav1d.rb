class Dav1d < Formula
  desc "AV1 decoder targeted to be small and fast"
  homepage "https://code.videolan.org/videolan/dav1d"
  url "http://ftp.debian.org/debian/pool/main/d/dav1d/dav1d_1.5.3.orig.tar.xz"
  sha256 "732010aa5ef461fa93355ed2c6c5fedb48ddc4b74e697eaabe8907eaeb943011"
  license "BSD-2-Clause"
  compatibility_version 1

  bottle do
    sha256 cellar: :any,                 arm64_tahoe:   "cda8a6b7d3184cb2a083b8629ae5f9b00f8e04b36da71d8f56f149cbdeebfdbf"
    sha256 cellar: :any,                 arm64_sequoia: "9502a86f722756284734b724206d21783a0863406462abf8d43fe52d5232bad5"
    sha256 cellar: :any,                 arm64_sonoma:  "fe0db93877e6734a127c1cb8dd98293d2016b830fd2ec36fb8985e36e92d7611"
    sha256 cellar: :any,                 sonoma:        "8697d509b54358c4ad2b8a370841ee5244431d2d85c2883bb7624f60c59ec7b6"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "89f1cacc3d5d6de20cd85b098e0abed0eaf552dbda07cb3715cf06decf5c1fcc"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "b8dae4c806758642d9e2dc6d064b0f62dd7b692c951c2bba171394ac94e69a8d"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    system "true"
  end
end
