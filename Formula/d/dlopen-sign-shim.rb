class DlopenSignShim < Formula
  desc "LD_PRELOAD shim to self-sign unsigned ELFs before dlopen on HarmonyOS"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo — the C source is generated inline in
  # install() below (originally written in-place inside opencode.rb before
  # being extracted here). Homebrew requires a url/resource on every
  # formula, so this pins to the tap's own repo; install() never reads
  # anything from the checkout, it only exists to satisfy that requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "f85bb6b03d69481502a275dd33b12e9ff213d7ed"
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/dlopen-sign-shim-v0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d95ad4fbcff79c20c47a0b10be676c12d6f1df14a4077b758d83622973703cd"
  end

  # Extracted from opencode.rb (originally written for its OpenTUI native
  # module loading). Runtimes that compile to a single file (Bun --compile,
  # PyInstaller-style bundlers, ...) extract embedded native modules
  # (.so/.node) to a scratch file at runtime and dlopen() them. OHOS rejects
  # unsigned ELFs with "Permission denied", and the extracted copy is never
  # signed by the runtime doing the extracting. This shim intercepts
  # dlopen/dlmopen and self-signs any unsigned ELF before delegating to the
  # real call.
  #
  # No TMPDIR-prefix scoping: callers extracting embedded resources don't
  # reliably honor $TMPDIR (observed Bun landing files under an OHOS-patched
  # musl libc default instead — see opencode.rb r2 history for the concrete
  # bug this caused). Sign any unsigned ELF this process tries to dlopen,
  # regardless of location — needs_signing() below already no-ops on non-ELF
  # and already-signed files, and a self-sign failure on a file we have no
  # business touching is silently discarded, so this is safe.
  depends_on "ohos-sdk" => :build
  depends_on "ohos-bst-light" # self-sign, invoked at runtime, not just build

  def install
    signer_path = formula_opt_bin("ohos-bst-light")/"self-sign"
    (buildpath/"dlopen_sign_shim.c").write <<~C
      #define _GNU_SOURCE
      #include <dlfcn.h>
      #include <elf.h>
      #include <fcntl.h>
      #include <stdlib.h>
      #include <string.h>
      #include <sys/wait.h>
      #include <unistd.h>
      static const char SIGNER[] = "#{signer_path}";
      /* Fail CLOSED (attempt to sign) on any open/read/parse error past the
       * point we know it's an ELF — a partially-written file mid-extraction
       * should not be silently treated as "already fine". The one exception
       * is the ELF-magic check itself: a definite non-ELF genuinely does not
       * need signing and self-sign would have nothing to do on it. */
      static int needs_signing(const char *path) {
        int fd = open(path, O_RDONLY);
        if (fd < 0) return 0;
        Elf64_Ehdr eh;
        if (read(fd, &eh, sizeof eh) != (ssize_t)sizeof eh) { close(fd); return 1; }
        if (memcmp(eh.e_ident, ELFMAG, SELFMAG) != 0) { close(fd); return 0; }
        Elf64_Shdr *sh = calloc(eh.e_shnum, sizeof(Elf64_Shdr));
        if (!sh) { close(fd); return 1; }
        if (lseek(fd, eh.e_shoff, SEEK_SET) < 0 ||
            read(fd, sh, (size_t)eh.e_shnum * sizeof(Elf64_Shdr)) !=
                (ssize_t)((size_t)eh.e_shnum * sizeof(Elf64_Shdr))) { free(sh); close(fd); return 1; }
        Elf64_Shdr *str = &sh[eh.e_shstrndx];
        char *names = malloc(str->sh_size);
        if (!names) { free(sh); close(fd); return 1; }
        if (lseek(fd, str->sh_offset, SEEK_SET) < 0 ||
            read(fd, names, str->sh_size) != (ssize_t)str->sh_size) { free(names); free(sh); close(fd); return 1; }
        close(fd);
        int has = 0;
        for (int i = 0; i < eh.e_shnum; i++) {
          if (strcmp(names + sh[i].sh_name, ".codesign") == 0) { has = 1; break; }
        }
        free(names); free(sh);
        return !has;
      }
      static void ensure_signed(const char *path) {
        if (!path) return;
        if (!needs_signing(path)) return;
        pid_t p = fork();
        if (p == 0) {
          /* Silence self-sign so its output does not corrupt an interactive
           * caller (e.g. a TUI). */
          int devnull = open("/dev/null", O_WRONLY);
          if (devnull >= 0) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
          }
          execl(SIGNER, "self-sign", path, (char *)NULL);
          _exit(127);
        }
        if (p > 0) { int st; while (waitpid(p, &st, 0) < 0) {} }
      }
      void *dlopen(const char *filename, int flags) {
        ensure_signed(filename);
        static void *(*real)(const char *, int);
        if (!real) real = (void *(*)(const char *, int))dlsym(RTLD_NEXT, "dlopen");
        return real(filename, flags);
      }
      void *dlmopen(long nsid, const char *filename, int flags) {
        ensure_signed(filename);
        static void *(*real)(long, const char *, int);
        if (!real) real = (void *(*)(long, const char *, int))dlsym(RTLD_NEXT, "dlmopen");
        return real(nsid, filename, flags);
      }
    C
    system formula_opt_bin("ohos-sdk")/"../native/llvm/bin/clang",
           "-shared", "-fPIC", "-o", "libdlopen_sign_shim.so",
           "dlopen_sign_shim.c", "-O2", "-Wall", "-Wextra"
    lib.install "libdlopen_sign_shim.so"
    # ohos-sdk clang already signs its output (adds a .codesign section);
    # self-sign errors on a file that's already signed rather than skipping,
    # so don't call it again here.
  end

  test do
    assert_path_exists lib/"libdlopen_sign_shim.so"
  end
end
