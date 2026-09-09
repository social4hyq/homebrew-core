class Traceroute < Formula
  desc "Trace the route taken by packets over an IPv4/IPv6 network"
  homepage "https://traceroute.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/traceroute/traceroute/traceroute-2.1.6/traceroute-2.1.6.tar.gz"
  sha256 "9ccef9cdb9d7a98ff7fbf93f79ebd0e48881664b525c4b232a0fcec7dcb9db5e"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://sourceforge.net/projects/traceroute/files/traceroute/"
    regex(/traceroute[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  def install
    # Make.rules leaks -l flags from LIBS into LIBDEPS, breaking the link.
    inreplace "Make.rules",
              "LIBDEPS = $(filter-out -L%,$(LIBS))",
              "LIBDEPS = $(filter-out -L% -l%,$(LIBS))"

    system "make"
    system "make", "prefix=#{prefix}", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/traceroute --version 2>&1")
  end
end
