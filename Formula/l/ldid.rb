class Ldid < Formula
  desc "Lets you manipulate the signature block in a Mach-O binary"
  homepage "https://cydia.saurik.com/info/ldid/"
  url "git://git.saurik.com/ldid.git",
      tag:      "v2.1.5",
      revision: "a23f0faadd29ec00a6b7fb2498c3d15af15a7100"
  license "AGPL-3.0-or-later"
  revision 1
  head "git://git.saurik.com/ldid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0192fc052435d0caa45d983fbf1398b154e093f0dbcda1c56043f1c638bd13be"
  end

  depends_on "libplist"
  depends_on "openssl@3"

  conflicts_with "ldid-procursus", because: "ldid-proucursus installs a conflicting ldid binary"

  def install
    ENV.append_to_cflags "-I."
    ENV.append "CXXFLAGS", "-std=c++11"
    linker_flags = %w[lookup2.o -lcrypto -lplist-2.0]

    system "make", "lookup2.o"
    system "make", "ldid", "LDLIBS=#{linker_flags.join(" ")}"

    bin.install "ldid"
    bin.install_symlink "ldid" => "ldid2"
  end

  test do
    cp test_fixtures("mach/a.out"), testpath
    system bin/"ldid", "-S", "a.out"
  end
end
