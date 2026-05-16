class Etsh < Formula
  desc "Two ports of /bin/sh from V6 UNIX (circa 1975)"
  homepage "https://etsh.dev/"
  url "https://etsh.dev/src/etsh_5.4.0/etsh-5.4.0.tar.xz"
  sha256 "fd4351f50acbb34a22306996f33d391369d65a328e3650df75fb3e6ccacc8dce"
  license all_of: ["BSD-2-Clause", "BSD-3-Clause", "BSD-4-Clause", :public_domain]
  version_scheme 1

  livecheck do
    url "https://etsh.dev/src/"
    regex(/href=.*?etsh[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01d4540f4204f3e7b4b60ee58d78dcfed8f18efae831579a767173d86b0f4f75"
  end

  conflicts_with "oils-for-unix", "omake", because: "both install `osh` binaries"
  conflicts_with "teleport", because: "both install `tsh` binaries"

  def install
    system "./configure"
    # The `tshall` target is not supported on Ubuntu 16.04 (https://etsh.nl/blog/ubuntu-16/)
    # so the `install-etshall` target must be used to only build `etshall`.
    # Check if `tshall` is supported in Ubuntu 18.04.
    install_target = OS.mac? ? "install" : "install-etshall"
    system "make", install_target, "PREFIX=#{prefix}", "SYSCONFDIR=#{etc}", "MANDIR=#{man1}"
    bin.install_symlink "etsh" => "osh"
    bin.install_symlink "tsh" => "sh6" if OS.mac?
  end

  test do
    assert_match "brew!", shell_output("#{bin}/etsh -c 'echo brew!'").strip
  end
end
