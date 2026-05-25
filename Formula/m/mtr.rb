class Mtr < Formula
  desc "'traceroute' and 'ping' in a single tool"
  homepage "https://www.bitwizard.nl/mtr/"
  url "https://github.com/traviscross/mtr/archive/refs/tags/v0.96.tar.gz"
  sha256 "73e6aef3fb6c8b482acb5b5e2b8fa7794045c4f2420276f035ce76c5beae632d"
  # Main license is GPL-2.0-only but some compatibility code is under other licenses:
  # 1. portability/queue.h is BSD-3-Clause
  # 2. portability/error.* is LGPL-2.0-only (only used on macOS)
  # 3. portability/getopt.* is omitted as unused
  license all_of: ["GPL-2.0-only", "BSD-3-Clause", "LGPL-2.0-only"]
  compatibility_version 1
  head "https://github.com/traviscross/mtr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "acec977f6b7247c8c248d7cfa18bfcc98c7e6f7e7adcb4e87f199a087dc7112b"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build
  depends_on "jansson"

  def install
    # Fix UNKNOWN version reported by `mtr --version`.
    inreplace "configure.ac",
              "m4_esyscmd([build-aux/git-version-gen .tarball-version])",
              version.to_s

    args = %W[
      --disable-silent-rules
      --without-glib
      --without-gtk
      --with-bashcompletiondir=#{bash_completion}
    ]
    system "./bootstrap.sh"
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  def caveats
    <<~EOS
      mtr requires root privileges so you will need to run `sudo mtr`.
      You should be certain that you trust any software you grant root privileges.
    EOS
  end

  test do
    # We patch generation of the version, so let's check that we did that properly.
    assert_match "mtr #{version}", shell_output("#{sbin}/mtr --version")
    if OS.mac?
      # mtr will not run without root privileges
      assert_match "Failure to open", shell_output("#{sbin}/mtr google.com 2>&1", 1)
      assert_match "Failure to open", shell_output("#{sbin}/mtr --json google.com 2>&1", 1)
    else
      # mtr runs but won't produce useful output without extra privileges
      assert_match "2.|-- ???", shell_output("#{sbin}/mtr google.com 2>&1")
      assert_match '"dst": "google.com"', shell_output("#{sbin}/mtr --json google.com 2>&1")
    end
  end
end
