class Ghc < Formula
  desc "Glorious Glasgow Haskell Compilation System"
  homepage "https://haskell.org/ghc/"
  url "https://downloads.haskell.org/~ghc/9.14.1/ghc-9.14.1-src.tar.xz"
  sha256 "2a83779c9af86554a3289f2787a38d6aa83d00d136aa9f920361dd693c101e77"
  license "BSD-3-Clause"
  revision 1
  head "https://gitlab.haskell.org/ghc/ghc.git", branch: "master"

  livecheck do
    url "https://www.haskell.org/ghc/"
    regex(/href=.*?download[_-]ghc[_-]v?(\d+(?:[._]\d+)+)\.html/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map { |match| match[0].tr("_", ".") }
    end
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ffc4393c16d1f670aea9709755187972665b94c4cd4faaf35fe7b7c2c5e9c43"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "python@3.14" => :build
  depends_on "sphinx-doc" => :build
  depends_on "xz" => :build
  depends_on "gmp"

  uses_from_macos "m4" => :build
  uses_from_macos "libffi"
  uses_from_macos "ncurses"

  # Build uses sed -r option, which is not available in Catalina shipped sed.
  on_catalina :or_older do
    depends_on "gnu-sed" => :build
  end

  # A binary of ghc is needed to bootstrap ghc
  # NOTE: GHC 9.12.3 fails https://gitlab.haskell.org/ghc/ghc/-/issues/26715
  resource "binary" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~ghc/9.12.2/ghc-9.12.2-aarch64-apple-darwin.tar.xz"
        sha256 "4b61b933028c63ace950236ea3382d02e51a3d9cbd1ca3f6cf4fe14c71ff436c"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.12.2/ghc-9.12.2-x86_64-apple-darwin.tar.xz"
        sha256 "e7a40e39059dd3619d7884b7382f357e79a0f4e430181b805bdd57b3be9a7300"
      end
    end
    on_linux do
      on_arm do
        url "https://github.com/Harmonybrew/ohos-ghc/releases/download/9.12.2/ghc-9.12.2-ohos-arm64.tar.gz"
        sha256 "5e85fee0e4e918438271c499734ba4c6d8396d0ebd357d3ed126f2c7437470e0"
      end
      on_intel do
        url "https://downloads.haskell.org/~ghc/9.12.2/ghc-9.12.2-x86_64-ubuntu20_04-linux.tar.xz"
        sha256 "0cffff0a74131465bb5d1447400ea46080a10e3cd46d6c9559aa6f2a6a7537ac"
      end
    end
  end

  resource "cabal-install" do
    on_macos do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-aarch64-darwin.tar.xz"
        sha256 "e02f4561fbce72b198a3c6c81b9f211f9c7cbf40c073f8f2ee59f835dd1dd502"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-x86_64-darwin.tar.xz"
        sha256 "e09fec9aa6379d79a749d337446fa72f03f880a577d149c7b039592860bea095"
      end
    end
    on_linux do
      on_arm do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-aarch64-linux-alpine3_22.tar.xz"
        sha256 "9a49d42a0d4962c960feab3ec2bcf6956bcc4ef04699237e4c0ab50037341f68"
      end
      on_intel do
        url "https://downloads.haskell.org/~cabal/cabal-install-3.16.1.0/cabal-install-3.16.1.0-x86_64-linux-ubuntu20_04.tar.xz"
        sha256 "4396b9beb4e77e9a732aea35c3f12fa0993a64ea32d257add4b7b7d5b23c7894"
      end
    end
  end

  patch do
    file "Patches/ghc/0001-support-ohos.patch"
  end

  def install
    # OpenHarmony (OHOS) SDK bundles the LLVM toolchain.
    # To ensure end-users can seamlessly compile Haskell programs on OHOS,
    # hardcode C/C++ compilers and linkers to native LLVM commands (clang/lld).
    # This prevents GHC from searching for non-existent system-wide `cc` or `ld`.
    ENV["CC"] = ENV["ac_cv_path_CC"] = "clang"
    ENV["CXX"] = ENV["ac_cv_path_CXX"] = "clang++"
    ENV["LD"] = ENV["MergeObjsCmd"] = "ld.lld"
    ENV["AR"] = "llvm-ar"
    ENV["RANLIB"] = "llvm-ranlib"
    ENV["PYTHON"] = which("python3.14")

    binary = buildpath/"binary"
    args = %W[
      --with-gmp-includes=#{Formula["gmp"].opt_include}
      --with-gmp-libraries=#{Formula["gmp"].opt_lib}
    ]

    resource("binary").stage do
      binary.install Dir["*"]
    end

    ENV.prepend_path "PATH", binary/"bin"
    # Build uses sed -r option, which is not available in Catalina shipped sed.
    ENV.prepend_path "PATH", Formula["gnu-sed"].libexec/"gnubin" if OS.mac? && MacOS.version <= :catalina

    resource("cabal-install").stage { (binary/"bin").install "cabal" }
    system "cabal", "v2-update"
    if build.head?
      cabal_args = std_cabal_v2_args.reject { |s| s["installdir"] }
      system "cabal", "v2-install", "alex", "happy", *cabal_args, "--installdir=#{binary}/bin"
      system "./boot"
    end

    if OS.mac?
      # https://gitlab.haskell.org/ghc/ghc/-/issues/22595#note_468423
      args << "--with-ffi-libraries=#{MacOS.sdk_path_if_needed}/usr/lib"
      args << "--with-ffi-includes=#{MacOS.sdk_path_if_needed}/usr/include/ffi"
    else
      args << "--with-ffi-libraries=#{Formula["libffi"].opt_lib}"
      args << "--with-ffi-includes=#{Formula["libffi"].opt_include}"
    end

    system "python3", "boot.source"
    chmod 0755, "configure"

    system "./configure", "--prefix=#{prefix}", "--disable-numa", "--with-system-libffi", *args
    hadrian_args = %W[
      -j#{ENV.make_jobs}
      --prefix=#{prefix}
      --flavour=release
      --docs=no-haddocks
      --docs=no-sphinx-html
      --docs=no-sphinx-pdfs
    ]
    # Let hadrian handle its own parallelization
    ENV.deparallelize { system "hadrian/build", "install", *hadrian_args }

    bash_completion.install "utils/completion/ghc.bash" => "ghc"
    ghc_libdir = build.head? ? lib.glob("ghc-*").first : lib/"ghc-#{version}"
    (ghc_libdir/"lib/package.conf.d/package.cache").unlink
    (ghc_libdir/"lib/package.conf.d/package.cache.lock").unlink

    # OpenHarmony musl uses namespace isolation: when GHC's dynamic linker
    # dlopen()s a Haskell-compiled .so at compile time (e.g. for Template
    # Haskell or cross-module optimization), the newly loaded library cannot
    # find RTS symbols (like stg_gc_unbx_r1) from the already-loaded
    # libHSrts.so because musl does NOT share symbols across library
    # boundaries by default.
    #
    # The fix is to set DF_1_GLOBAL in DT_FLAGS_1 on every libHSrts*.so,
    # which tells the musl dynamic linker to place their symbols in the
    # global symbol namespace, making them visible to subsequently
    # dlopen()'d libraries. Without this, building any non-trivial Haskell
    # package (e.g. directory-ospath-streaming via cabal-install) fails with
    # "Error relocating ... stg_gc_unbx_r1: symbol not found".
    rts_script = buildpath/"elf_patch_rts_global.py"
    rts_script.write <<~PYTHON
      import struct, sys

      def patch_elf(so_path):
          with open(so_path, "r+b") as f:
              data = bytearray(f.read())

              # 64-bit ELF only
              if data[4] != 2:
                  return False

              shoff = struct.unpack_from("<Q", data, 0x28)[0]
              shentsize = struct.unpack_from("<H", data, 0x3A)[0]
              shnum = struct.unpack_from("<H", data, 0x3C)[0]
              shstrndx = struct.unpack_from("<H", data, 0x3E)[0]

              shstrtab_off = shoff + shstrndx * shentsize
              shstrtab_sh_offset = struct.unpack_from("<Q", data, shstrtab_off + 0x18)[0]

              for i in range(shnum):
                  sh_off = shoff + i * shentsize
                  sh_name = struct.unpack_from("<I", data, sh_off)[0]
                  name = data[shstrtab_sh_offset + sh_name:].split(b"\\0")[0].decode()

                  if name == ".dynamic":
                      dyn_offset = struct.unpack_from("<Q", data, sh_off + 0x18)[0]
                      dyn_size = struct.unpack_from("<Q", data, sh_off + 0x20)[0]
                      n_entries = dyn_size // 16

                      patched = False
                      for j in range(n_entries):
                          entry_off = dyn_offset + j * 16
                          d_tag = struct.unpack_from("<q", data, entry_off)[0]
                          if d_tag == 0x6ffffffb:  # DT_FLAGS_1
                              d_val = struct.unpack_from("<Q", data, entry_off + 8)[0]
                              d_val |= 0x2  # DF_1_GLOBAL
                              struct.pack_into("<Q", data, entry_off + 8, d_val)
                              patched = True
                              break
                      if patched:
                          f.seek(0)
                          f.truncate()
                          f.write(data)
                          return True
                      break
              return False

      if __name__ == "__main__":
          so_path = sys.argv[1]
          ok = patch_elf(so_path)
          sys.exit(0 if ok else 1)
    PYTHON

    rts_glob = "#{ghc_libdir}/lib/*/libHSrts*.so"
    Pathname.glob(rts_glob).each do |so|
      ohai "Adding DF_1_GLOBAL to #{so.basename}"
      system "python3", rts_script.to_s, so.to_s
    end
  end

  def post_install
    system bin/"ghc-pkg", "recache"
  end

  test do
    (testpath/"hello.hs").write('main = putStrLn "Hello Homebrew"')
    assert_match "Hello Homebrew", shell_output("#{bin}/runghc hello.hs")
  end
end
