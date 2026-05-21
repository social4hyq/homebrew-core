class Daemontools < Formula
  desc "Collection of tools for managing UNIX services"
  homepage "https://cr.yp.to/daemontools.html"
  url "https://cr.yp.to/daemontools/daemontools-0.76.tar.gz"
  sha256 "a55535012b2be7a52dcd9eccabb9a198b13be50d0384143bd3b32b8710df4c1f"
  license :public_domain
  revision 2

  livecheck do
    url "https://cr.yp.to/daemontools/install.html"
    regex(/href=.*?daemontools[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c58697fba1c82a2ab0e007637b6c9743b84e57a92c070231c690264a6431b646"
  end

  resource "man" do
    url "https://deb.debian.org/debian/pool/main/d/daemontools/daemontools_0.76-8.1.debian.tar.xz"
    sha256 "b9a1ed0ea88172d921738237c48e67cbe3b04e5256fea8ec00f32116c9ef74c0"
  end

  # Fix build failure due to missing #include <errno.h> on Linux.
  # Patch submitted to author by email.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/daemontools/errno.patch"
    sha256 "b7beb4cfe150b5cad1f50f4879d91cd8fc72e581940da4a716b99467d3a14937"
  end

  # Fix build failure due to missing headers for POSIX-related functions.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/daemontools/posix-headers.patch"
    sha256 "288afdf9b7ba4f05a791f714ddea22b0a18020f54face020e45311135f0c92c1"
  end

  def install
    cd "daemontools-#{version}" do
      inreplace ["package/run", "src/svscanboot.sh"] do |s|
        s.gsub! "/service", "#{etc}/service"
        s.gsub! "/command", bin.to_s
      end

      # Work around build error from root requirement: "Oops. Your getgroups() returned 0,
      # and setgroups() failed; this means that I can't reliably do my shsgr test. Please
      # either ``make'' as root or ``make'' while you're in one or more supplementary groups."
      inreplace "src/Makefile", "( cat warn-shsgr; exit 1 )", "cat warn-shsgr" if OS.linux?

      system "package/compile"
      bin.install Dir["command/*"]
    end

    resource("man").stage do
      man8.install Dir["daemontools-man/*.8"]
    end
  end

  def post_install
    (etc/"service").mkpath

    Pathname.glob("/service/*") do |original|
      target = "#{etc}/service/#{original.basename}"
      ln_s original, target unless File.exist?(target)
    end
  end

  def caveats
    <<~EOS
      Services are stored in:
        #{etc}/service/
    EOS
  end

  service do
    run opt_bin/"svscanboot"
    keep_alive true
    require_root true
  end

  test do
    assert_match "Homebrew", shell_output("#{bin}/softlimit -t 1 echo 'Homebrew'")
  end
end
