class Pgbackrest < Formula
  desc "Reliable PostgreSQL Backup & Restore"
  homepage "https://pgbackrest.org"
  url "https://github.com/pgbackrest/pgbackrest/releases/download/release/2.59.1/pgbackrest-2.59.1.tar.gz"
  sha256 "1cd522afc33b8ff846ef88c55dc238717c9c8817a4f6ca7c9f64887de9c7402d"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d220805e7146ae622cc02bc23d3fc7df8f3d836b168727a9ae3fbf7bd1825ae5"
  end

  depends_on "cmake" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "libpq"
  depends_on "libssh2"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "zstd"

  uses_from_macos "bzip2"
  uses_from_macos "libxml2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath(target: Formula["libpq"].opt_lib)}" if OS.linux?

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    # pgbackrest 2.59+ refuses to run the info command as root, which is the
    # case in the OHOS build environment (only the root user exists).
    args = Process.uid.zero? ? ["--allow-root"] : []
    output = shell_output("#{bin}/pgbackrest info #{args.join(" ")}")
    assert_match "No stanzas exist in the repository.", output
  end
end
