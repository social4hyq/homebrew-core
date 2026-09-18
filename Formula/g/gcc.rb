class Gcc < Formula
  desc "GNU compiler collection"
  homepage "https://gcc.gnu.org/"
  url "https://ftpmirror.gnu.org/gcc/gcc-16.2.0/gcc-16.2.0.tar.xz"
  mirror "https://ftp.gnu.org/gnu/gcc/gcc-16.2.0/gcc-16.2.0.tar.xz"
  sha256 "e6738e29597f733270731aa90600f37ffdc045079dfc27ec7e8192cc81085c3e"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }
  compatibility_version 2
  head "https://gcc.gnu.org/git/gcc.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{href=["']?gcc[._-]v?(\d+(?:\.\d+)+)(?:/?["' >]|\.t)}i)
  end

  bottle do
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d01be33349a239848a0bbc934ee8e045eed50698f3df589897787497aff6cd34"
  end

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  pour_bottle? only_if: :clt_installed

  depends_on "gmp"
  depends_on "isl"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "ohos-sdk-native" if OS.ohos? # sysroot, libc and crt*.o
  depends_on "zstd"

  uses_from_macos "flex" => :build
  uses_from_macos "m4" => :build

  on_macos do
    # macOS make is too old, has intermittent parallel build issue
    depends_on "make" => :build
  end

  on_linux do
    depends_on "binutils"
    depends_on "zlib-ng-compat"
  end

  conflicts_with "llvm-gcc-compat", because: "both install `gcc` binaries"

  # ═══════════════════════════════════════════════════════════════════
  # HarmonyOS patches
  #
  # Upstream GCC has no *-*-linux-ohos target, so the patches here add the
  # smallest target support that works on the platform:
  #
  #   0001: Teach config.sub/config.gcc about *-*-linux-ohos. OpenHarmony's
  #         libc is musl, so the target reuses GCC's existing musl support
  #         (DEFAULT_LIBC=LIBC_MUSL: /lib/ld-musl-aarch64.so.1 as the dynamic
  #         linker and the sysroot's usr/lib/aarch64-linux-ohos as the library
  #         directory) rather than growing a target of its own, and libgcc and
  #         libstdc++ only have to be told that OHOS is musl-flavoured too.
  #         libgcc also treats OHOS the way it treats Bionic, since the SDK
  #         this port builds against declares no pthread_cancel, and the
  #         target headers add the macros the platform's own toolchain
  #         defines.
  #
  #   0002: Make the sysroot's headers usable with upstream's C23 default. A
  #         declaration with an empty parameter list that comes from a system
  #         header keeps its old-style meaning (`<string.h>` has
  #         `char *basename()`, which C23 would otherwise read as taking no
  #         arguments), and the Clang-only `__availability__(ohos, ...)`
  #         annotation is swallowed by a built-in macro.
  #
  #   0003: The probe that decides whether libgfortran's Coarray (caf) SHMEM
  #         support can be built only checks the process-shared pthread API,
  #         not the robust-mutex API that caf/shmem/thread_support.c also uses.
  #         OpenHarmony's libc does not provide the latter, so check for it and
  #         disable that implementation instead of failing to compile.
  #
  #   0004: genmatch's diagnostic self-test (only built for a bootstrapping
  #         build) writes through fmemopen() and then inspects the caller's
  #         buffer, which OpenHarmony's musl does not fill in — the platform's
  #         own clang builds behave the same way — so skip it.
  #
  #   0005: OpenHarmony's <fortify/*.h> headers, which the libc headers pull in
  #         when `_FORTIFY_SOURCE` is defined, are written for Clang
  #         (`pass_object_size`, `enable_if`, `diagnose_if`), none of which GCC
  #         implements. Install stubs under those names into the compiler's own
  #         include directory - which is searched before the sysroot - so that
  #         a build asking for fortification gets one clear error instead of a
  #         screenful of attribute errors from the sysroot. GCC never defines
  #         the macro by itself, so nothing changes for a build that does not
  #         ask for it.
  #
  # GCC's own runtime handling is left exactly as upstream has it, libgcc
  # included. The two OHOS-only additions are both made at install time and are
  # commented where they happen: the unversioned `gcc`/`g++` names, and the
  # rpath that `generate_specs` writes.
  #
  # The sysroot itself is left alone: it belongs to another formula, and the
  # header problems that would otherwise tempt a patch to it are handled on the
  # compiler side instead - see 0002 for the C standard and the availability
  # annotation, and 0005 for fortify.
  # ═══════════════════════════════════════════════════════════════════

  patch do
    file "Patches/gcc/0001-ohos-target-support.patch"
  end

  patch do
    file "Patches/gcc/0002-ohos-system-headers.patch"
  end

  patch do
    file "Patches/gcc/0003-caf-shmem-robust-mutex.patch"
  end

  patch do
    file "Patches/gcc/0004-skip-genmatch-selftest.patch"
  end

  patch do
    file "Patches/gcc/0005-ohos-fortify-stubs.patch"
  end

  # Stock builds run on a Linux kernel whose userland is OpenHarmony, so
  # config.guess would report a `*-linux-gnu` triple for a system that is
  # musl-based. Both triples are therefore passed explicitly, and the target
  # triple is also the multiarch directory of the sysroot's libraries.
  HOST_TRIPLE = "aarch64-unknown-linux-ohos".freeze
  TARGET_TRIPLE = "aarch64-linux-ohos".freeze

  def version_suffix
    if build.head?
      "HEAD"
    else
      version.major.to_s
    end
  end

  deny_network_access!

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    # We avoiding building:
    #  - Ada and D, which require a pre-existing GCC to bootstrap
    #  - Cobol, not fully stable yet
    #  - Go, currently not supported on macOS
    #  - BRIG
    #  - Modula-2 on macOS, https://github.com/Homebrew/homebrew-core/pull/221029
    languages = %w[c c++ objc obj-c++ fortran]
    languages << "m2" unless OS.mac?

    pkgversion = "Homebrew GCC #{pkg_version}"

    # Use `lib/gcc/current` to provide a path that doesn't change with GCC's version.
    args = %W[
      --prefix=#{opt_prefix}
      --libdir=#{opt_lib}/gcc/current
      --disable-nls
      --enable-checking=release
      --with-gcc-major-version-only
      --enable-languages=#{languages.join(",")}
      --program-suffix=-#{version_suffix}
      --with-gmp=#{formula_opt_prefix("gmp")}
      --with-mpfr=#{formula_opt_prefix("mpfr")}
      --with-mpc=#{formula_opt_prefix("libmpc")}
      --with-isl=#{formula_opt_prefix("isl")}
      --with-zstd=#{formula_opt_prefix("zstd")}
      --with-pkgversion=#{pkgversion}
      --with-bugurl=#{tap.issues_url}
      --with-system-zlib
    ]

    if OS.mac?
      cpu = Hardware::CPU.arm? ? "aarch64" : "x86_64"
      args << "--build=#{cpu}-apple-darwin#{OS.kernel_version.major}"

      sdk = MacOS.sdk_path
      args << "--with-sysroot=#{sdk}" if sdk

      # Avoid this semi-random failure:
      # "Error: Failed changing install name"
      # "Updated load commands do not fit in the header"
      make_args = %w[
        BOOT_LDFLAGS=-Wl,-headerpad_max_install_names
        LDFLAGS_FOR_TARGET=-Wl,-headerpad_max_install_names
      ]
    else
      args << "--disable-multilib"
      args << "--with-linker-hash-style=gnu"

      # Enable to PIE by default to match what the host GCC uses
      args << "--enable-default-pie"

      # Change the default directory name for 64-bit libraries to `lib`
      # https://stackoverflow.com/a/54038769
      inreplace "gcc/config/i386/t-linux64", "m64=../lib64", "m64="
      inreplace "gcc/config/aarch64/t-aarch64-linux", "lp64=../lib64", "lp64="

      ENV.append_path "CPATH", formula_opt_include("zlib-ng-compat")
      ENV.append_path "LIBRARY_PATH", formula_opt_lib("zlib-ng-compat")
    end

    if OS.ohos?
      ohos_sdk_native = formula_opt_prefix("ohos-sdk-native")
      sysroot         = ohos_sdk_native/"sysroot"
      odie "OpenHarmony sysroot missing: #{sysroot}/usr/lib/#{TARGET_TRIPLE}" unless
        (sysroot/"usr/lib"/TARGET_TRIPLE).directory?

      # The compiler proper (cc1, ...) links against these kegs and against the
      # SDK's libc++ (the host compiler is clang, and OHOS' own C++ runtime is
      # libc++). OHOS' musl has no ld.so.conf/ld.so.cache to fall back on, so
      # record the paths in the binaries themselves.
      rpaths = %w[gmp isl libmpc mpfr zstd zlib-ng-compat].map { |dep| formula_opt_lib(dep).to_s }
      rpaths << (ohos_sdk_native/"llvm/lib"/TARGET_TRIPLE).to_s
      rpaths.uniq!
      rpath_flags = rpaths.map { |dir| "-Wl,-rpath,#{dir}" }
      ENV.append "LDFLAGS", rpath_flags.join(" ")

      # --enable-host-pie: OpenHarmony defaults to PIE, and non-PIE objects
      # reach `stdout` — a copy-relocated symbol in the sysroot's libc —
      # through a direct ADRP+LDR pair that the linker cannot encode when the
      # copy is not 8-byte aligned, which is how the Modula-2 bootstrap
      # compiler (gcc/m2/pge) failed to link.
      #
      # --disable-libsanitizer: libsanitizer does not compile against this
      # sysroot, as its sanitizer_common pulls in <linux/sysinfo.h> next to the
      # sysroot's own <sys/sysinfo.h> and the two `struct sysinfo` definitions
      # cannot coexist.
      #
      # A bootstrapping build links stages 2 and 3 with these flags instead of
      # any LDFLAGS from the environment, so the rpaths have to be repeated
      # here; upstream's default (`-static-libstdc++ -static-libgcc`) is kept
      # for the compiler's own binaries, as the brewed libstdc++ and libgcc do
      # not exist yet while GCC is being bootstrapped.
      boot_ldflags = (["-static-libstdc++", "-static-libgcc"] + rpath_flags).join(" ")

      args += %W[
        --enable-host-pie
        --disable-libsanitizer
        --build=#{HOST_TRIPLE}
        --host=#{HOST_TRIPLE}
        --target=#{TARGET_TRIPLE}
        --with-sysroot=#{sysroot}
        --with-boot-ldflags=#{boot_ldflags}
      ]
    end

    mkdir "build" do
      # Do not strip the binaries on macOS, it makes them unsuitable for loading plugins
      install_target = OS.mac? ? "install" : "install-strip"

      # To make sure GCC does not record cellar paths, we configure it with
      # opt_prefix as the prefix. Then we use DESTDIR to install into a
      # temporary location, then move into the cellar path.
      if OS.ohos?
        # Two configure answers are given through a site file:
        #
        # * OpenHarmony's userland has no `gmake`, and both the top-level and
        #   the gcc configure script probe for an Ada compiler by compiling a
        #   file with `-x ada`, which re-executes clang there until it runs out
        #   of processes.
        #
        # * `ac_cv_func_posix_fallocate=no` leaves HAVE_POSIX_FALLOCATE
        #   undefined, so the C++ module writer sizes its output with
        #   ftruncate() from the start.  Its ftruncate() fallback only runs when
        #   posix_fallocate() reports EINVAL, and OpenHarmony's home directory
        #   (hmdfs) answers EACCES instead - any other non-EINVAL answer would
        #   do the same: the module output is left unmapped and writing it out
        #   dereferences NULL, crashing cc1plus with SIGSEGV.
        (buildpath/"ohos-config.site").write <<~EOS
          acx_cv_cc_gcc_supports_ada=no
          ac_cv_func_posix_fallocate=no
        EOS
        with_env CONFIG_SITE: buildpath/"ohos-config.site" do
          system "../configure", *args
          system "make"
          system "make", install_target, "DESTDIR=#{buildpath}/instdir"
        end

        # libobjc's hand-written Makefile has no `install-strip` rule — unlike
        # the other target libraries — so asking for it silently leaves out the
        # Objective-C runtime and its <objc/*.h> headers.
        system "make", "install-target-libobjc", "DESTDIR=#{buildpath}/instdir"
      else
        system "../configure", *args
        system "gmake", *make_args
        system "gmake", install_target, "DESTDIR=#{buildpath}/instdir"
      end
      prefix.install buildpath.glob("instdir/#{opt_prefix}/*")
    end

    bin.install_symlink bin/"gfortran-#{version_suffix}" => "gfortran"
    bin.install_symlink bin/"gm2-#{version_suffix}" => "gm2"

    # Upstream installs no unversioned names beyond `gfortran`/`gm2` above: on
    # macOS and Linux the rest are clang or whatever the distribution provides.
    # An OpenHarmony device has neither, so every program this keg installs gets
    # its unversioned name, and - as a distribution's native GCC does, where
    # `aarch64-linux-gnu-gcc` sits beside `gcc` - its target-prefixed name too.
    if OS.ohos?
      %w[c++ cpp gcc g++ gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool
         lto-dump].each do |name|
        bin.install_symlink bin/"#{name}-#{version_suffix}" => name
      end

      %w[c++ g++ gcc gcc-ar gcc-nm gcc-ranlib gfortran gm2].each do |name|
        versioned = "#{TARGET_TRIPLE}-#{name}-#{version_suffix}"
        bin.install_symlink bin/versioned => "#{TARGET_TRIPLE}-#{name}"
      end
    end

    # Provide a `lib/gcc/xy` directory to align with the versioned GCC formulae.
    # We need to create `lib/gcc/xy` as a directory and not a symlink to avoid `brew link` conflicts.
    (lib/"gcc"/version_suffix).install_symlink (lib/"gcc/current").children

    # Only the newest brewed gcc should install gfortan libs as we can only have one.
    lib.install_symlink lib.glob("gcc/current/libgfortran.*") if OS.linux?

    # Rename man7 to avoid conflicts between GCC formulae
    man7.glob("*.7") { |file| add_suffix file, version_suffix }
    # Even when we disable building info pages some are still installed.
    rm_r(info)

    # How the target runtimes are linked is left to upstream. OpenHarmony's
    # libc has no ld.so.conf/ld.so.cache, though, and the shared libgcc the C++
    # and Fortran drivers link lives in this keg, so the programs GCC produces
    # are given an rpath to it - see `generate_specs`.
    generate_specs if OS.ohos?
  end

  def add_suffix(file, suffix)
    dir = File.dirname(file)
    ext = File.extname(file)
    base = File.basename(file, ext)
    File.rename file, "#{dir}/#{base}-#{suffix}#{ext}"
  end

  # `configure_gcc_runtime` is for glibc systems: it points the dynamic linker
  # at `#{HOMEBREW_PREFIX}/lib/ld.so`, adds an `-isysroot` that does not exist,
  # and puts the Homebrew prefix into the header and library search paths. None
  # of that applies here - OpenHarmony's libc and loader are the system's, and
  # the platform's own compiler searches nothing but the SDK - so only the
  # rpath `generate_specs` writes is added.
  unless OS.ohos?
    post_install_steps do
      configure_gcc_runtime
    end
  end

  # Write the specs file the driver reads from its own library directory.
  #
  # OpenHarmony's musl has no ld.so.conf/ld.so.cache to fall back on, and the
  # shared libgcc that the C++ and Fortran drivers link by default is only in
  # this keg, so programs are given an rpath to that directory. It is the ELF
  # equivalent of the absolute install names Homebrew's GCC records in the
  # dylibs it ships on macOS, and it is the only path this compiler adds: the
  # rest of what Homebrew's Linux GCC gets from `configure_gcc_runtime` - the
  # prefix in the header and library search paths, the Homebrew dynamic linker
  # - is left out deliberately, because OpenHarmony's own compiler searches
  # nothing but the SDK's sysroot and there is no Homebrew libc or loader here
  # for those entries to point at.
  #
  # `opt_lib` rather than the keg's own path keeps the rpath valid after GCC is
  # updated.
  def generate_specs
    gcc = bin/"gcc-#{version_suffix}"
    libgcc_dir = Pathname(Utils.safe_popen_read(gcc, "-print-libgcc-file-name").strip).dirname
    specs = libgcc_dir/"specs"

    specs.write Utils.safe_popen_read(gcc, "-dumpspecs") + <<~EOS
      *link:
      + %{!static:-rpath #{opt_lib}/gcc/current}
    EOS
  end

  def caveats
    <<~EOS
      This GCC build is from upstream source code without deep
      adaptation for OpenHarmony. Its stability is not guaranteed.
      For production use, please use ohos-sdk first.

      Programs link this keg's runtimes (libgcc_s, libstdc++, libgfortran, ...)
      shared, and record its directory as an rpath, as they do with Homebrew's
      GCC on Linux. To build a program that does not need this keg, link the
      runtimes it uses statically - e.g. `-static-libgcc`, `-static-libstdc++`
      or `-static-libgfortran`.
    EOS
  end

  test do
    (testpath/"hello-c.c").write <<~C
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    C
    system bin/"gcc-#{version_suffix}", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", shell_output("./hello-c")

    (testpath/"hello-cc.cc").write <<~CPP
      #include <iostream>
      struct exception { };
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        try { throw exception{}; }
          catch (exception) { }
          catch (...) { }
        return 0;
      }
    CPP
    system bin/"g++-#{version_suffix}", "-o", "hello-cc", "hello-cc.cc"
    assert_equal "Hello, world!\n", shell_output("./hello-cc")

    (testpath/"test.f90").write <<~FORTRAN
      integer,parameter::m=10000
      real::a(m), b(m)
      real::fact=0.5

      do concurrent (i=1:m)
        a(i) = a(i) + fact*b(i)
      end do
      write(*,"(A)") "Done"
      end
    FORTRAN
    system bin/"gfortran", "-o", "test", "test.f90"
    assert_equal "Done\n", shell_output("./test")

    # Modula-2 is temporarily disabled on macOS
    return if OS.mac?

    (testpath/"hello.mod").write <<~MODULA2
      MODULE hello;
      FROM InOut IMPORT WriteString, WriteLn;
      BEGIN
           WriteString("Hello, world!");
           WriteLn;
      END hello.
    MODULA2
    system bin/"gm2", "-o", "hello-m2", "hello.mod"
    assert_equal "Hello, world!\n", shell_output("./hello-m2")
  end
end
