class Miniupnpc < Formula
  desc "UPnP IGD client library and daemon"
  homepage "https://miniupnp.tuxfamily.org"
  url "https://miniupnp.tuxfamily.org/files/download.php?file=miniupnpc-2.3.3.tar.gz"
  mirror "http://miniupnp.free.fr/files/miniupnpc-2.3.3.tar.gz"
  sha256 "d52a0afa614ad6c088cc9ddff1ae7d29c8c595ac5fdd321170a05f41e634bd1a"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/miniupnp/miniupnp.git", branch: "master"

  # We only match versions with only a major/minor since versions like 2.1 are
  # stable and versions like 2.1.20191224 are unstable/development releases.
  livecheck do
    url "https://miniupnp.tuxfamily.org/files/"
    regex(/href=.*?miniupnpc[._-]v?(\d+\.\d+(?>.\d{1,7})*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3dd8291bddd6d683b5157393bb2857bfb6e2dd2eef3bc500568a1b9797b5d721"
  end

  def install
    # When building from head we have to cd into the miniupnpc directory
    build_dir = build.head? ? "miniupnpc" : "."

    cd build_dir do
      system "make", "INSTALLPREFIX=#{prefix}", "install"
    end
  end

  test do
    # `No IGD UPnP Device` on CI
    output = shell_output("#{bin}/upnpc -l 2>&1", 1)
    assert_match "No IGD UPnP Device found on the network !", output

    output = shell_output("#{bin}/upnpc --help 2>&1")
    assert_match version.to_s, output
  end
end
