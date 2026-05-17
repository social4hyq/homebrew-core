class Gqlplus < Formula
  desc "Drop-in replacement for sqlplus, an Oracle SQL client"
  homepage "https://gqlplus.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/gqlplus/gqlplus/1.16/gqlplus-1.16.tar.gz"
  sha256 "9e0071d6f8bc24b0b3623c69d9205f7d3a19c2cb32b5ac9cff133dc75814acdd"
  license "GPL-2.0-only"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e879be5e9a28aaf642b8aefce5b66c85acea7070fd8e43632740bacefc2753c"
  end

  # readline's license is incompatible with GPL-2.0-only.
  # We also cannot use macOS libedit as it lacks _history_list
  depends_on "libedit"

  def install
    ENV.append_to_cflags "-I#{Formula["libedit"].opt_libexec}/include"
    ENV.append "LDFLAGS", "-L#{Formula["libedit"].opt_libexec}/lib"

    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    # Fix the version
    # Reported 18 Jul 2016: https://sourceforge.net/p/gqlplus/bugs/43/
    inreplace "gqlplus.c",
      "#define VERSION          \"1.15\"",
      "#define VERSION          \"1.16\""

    system "./configure", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gqlplus -h")
  end
end
