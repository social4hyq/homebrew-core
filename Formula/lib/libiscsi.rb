class Libiscsi < Formula
  desc "Client library and utilities for iscsi"
  homepage "https://github.com/sahlberg/libiscsi"
  url "https://github.com/sahlberg/libiscsi/archive/refs/tags/1.20.3.tar.gz"
  sha256 "212f6e1fd8e7ddb4b02208aafc6de600f6f330f40359babeefdd83b0c79d47a1"
  license all_of: [:public_domain, "LGPL-2.1-or-later", "GPL-2.0-or-later"]
  head "https://github.com/sahlberg/libiscsi.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b33cfa59a0ddc081b2d60426c515216536f02495992df03847e03f951e9f37bf"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "cunit"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"iscsi-ls", "--help"
    system bin/"iscsi-test-cu", "--list"
  end
end
