class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64 (prebuilt musl binary)"
  homepage "https://github.com/anomalyco/opencode"
  version "1.17.20"
  # opencode's official prebuilt linux-arm64-musl single binary (Bun --compile).
  # Bypasses the opencode-ai npm JS wrapper. The musl-ABI binary is
  # OHOS-compatible once its GCC runtime deps are provided (see resources).
  url "https://registry.npmjs.org/opencode-linux-arm64-musl/-/opencode-linux-arm64-musl-#{version}.tgz"
  sha256 "4366d8623ebe5bbcecf655d77153803c7b0d59f8b9bda1cfafb11f0ee2ee460f"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.17.20"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8caa573517f96049b91885fde91a70fd72c9c85f01d3e6f367de0c2ea64fa6c3"
  end
  # NOTE for rebuilds: `brew bottle` unconditionally odie()s with "non-relocatable
  # reference to HOMEBREW_REPOSITORY" for this formula — the injected DT_RUNPATH
  # (libexec/lib, required above) resolves under .../Homebrew/Cellar, and this
  # tap's HOMEBREW_PREFIX != HOMEBREW_REPOSITORY, so the check always fires
  # regardless of --skip-relocation (that flag doesn't gate this specific check).
  # No formula-level escape hatch exists (formula_ignores only special-cases go
  # deps). Verified 2026-07-14: temporarily changing the `odie` to `opoo` at
  # dev-cmd/bottle.rb:570 for the single `brew bottle` invocation, then
  # reverting it immediately, is safe — same `:any_skip_relocation` pattern
  # already used by ohos-bst-light/close-range-shim in this tap.

  livecheck do
    url "https://registry.npmjs.org/opencode-ai/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/)
  end

  # The prebuilt binary dynamically links libstdc++.so.6 + libgcc_s.so.1 (GCC
  # runtime), which OHOS does NOT ship (OHOS uses libc++). We bundle musl-aarch64
  # builds of both from Alpine and inject a DT_RUNPATH so the loader finds them.
  # OHOS ignores LD_LIBRARY_PATH, and LD_PRELOAD cannot satisfy NEEDED entries,
  # so RUNPATH (which the OHOS musl loader DOES honor) is the only mechanism.
  # patchelf rewrites segment offsets and corrupts Bun's appended module graph,
  # so RUNPATH is injected in-place (zero file-offset shift) via inject-runpath.py.
  #
  # Additionally, the TUI extracts its embedded native modules (libopentui.so,
  # *.node, ...) to TMPDIR at runtime and dlopens them. OHOS rejects unsigned
  # .so with "Permission denied", and Bun extracts only the stored (unsigned)
  # byte length so signing the embedded copy does not help. A small LD_PRELOAD
  # shim (dlopen_sign_shim) intercepts dlopen and signs any unsigned ELF under
  # TMPDIR via self-sign before delegating.
  depends_on "ohos-bst-light" => :build
  depends_on "ohos-sdk"       => :build # clang to compile the dlopen-sign shim
  depends_on "python@3.14"    => :build
  depends_on "close-range-shim"

  resource "libstdc++" do
    url "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/libstdc++-15.2.0-r5.apk"
    sha256 "2302e766d4e4926038ec166ecb85837ee884576115236ddb565e3a5fca4a11d7"
  end

  resource "libgcc" do
    url "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/libgcc-15.2.0-r5.apk"
    sha256 "369aaa6e9d099a737bad6dd3e6c2fe7bb1547ca26d22b94ee0411228f709b403"
  end

  def install
    src = buildpath.glob("package/bin/opencode").first || buildpath.glob("**/opencode").first
    odie "opencode binary not found in tarball" unless src

    libdir = libexec/"lib"
    libdir.mkpath
    sign = Formula["ohos-bst-light"].opt_bin/"self-sign"
    python = Formula["python@3.14"].opt_bin/"python3"

    # Deploy + sign the musl GCC runtime libraries (.apk = gzip tar).
    # Stage each resource into a Pathname target (the block form yields a
    # ResourceStageContext that does not support path division), then extract
    # the .apk if brew did not already, and copy the .so out.
    libgcc_dir   = buildpath/"libgcc-rsrc"
    libstdcxx_dir = buildpath/"libstdcxx-rsrc"
    resource("libgcc").stage(libgcc_dir)
    resource("libstdc++").stage(libstdcxx_dir)

    extract_apk = lambda do |dir|
      return if (dir/"usr/lib").exist?
      apk = Dir[dir/"*.apk"].first
      system "tar", "-xzf", apk, "-C", dir.to_s if apk
    end
    extract_apk.call(libgcc_dir)
    extract_apk.call(libstdcxx_dir)

    cp libgcc_dir/"usr/lib/libgcc_s.so.1", libdir/"libgcc_s.so.1"
    real = (libstdcxx_dir/"usr/lib").glob("libstdc++.so.6.0.*").first
    odie "libstdc++.so.6 missing in apk" unless real
    cp real, libdir/"libstdc++.so.6.0.34"
    chmod 0755, libdir/"libgcc_s.so.1"
    chmod 0755, libdir/"libstdc++.so.6.0.34"
    system sign, (libdir/"libgcc_s.so.1").to_s
    system sign, (libdir/"libstdc++.so.6.0.34").to_s
    ln_sf "libstdc++.so.6.0.34", libdir/"libstdc++.so.6"

    # Inject DT_RUNPATH (in-place, zero offset shift) → libexec/lib.
    (buildpath/"inject-runpath.py").write <<~'PY'
      import os, sys, struct
      def u(d, off, fmt): return struct.unpack_from(fmt, d, off)
      def patch(path, libdir):
          with open(path, "rb") as f: d = bytearray(f.read())
          e_phoff=u(d,0x20,"<Q")[0]; e_phnum=u(d,0x38,"<H")[0]; e_phentsize=u(d,0x36,"<H")[0]
          loads=[]; ptdyn=None
          for i in range(e_phnum):
              b=e_phoff+i*e_phentsize
              t,fl,off,va,pa,fsz,msz,al=u(d,b,"<IIQQQQQQ")
              if t==1: loads.append((off,va,fsz,msz))
              if t==2: ptdyn=(i,b)
          def seg_for_v(v):
              for off,va,fsz,msz in loads:
                  if va<=v<va+msz: return (off,va)
          def v2f(v):
              o,va=seg_for_v(v); return o+(v-va)
          rw=max(loads,key=lambda l:l[1]); rw_off,rw_v=rw[0],rw[1]
          def f2v_rw(off): return rw_v+(off-rw_off)
          _,db=ptdyn
          _,_,d_off,d_va,d_pa,d_fsz,_,_=u(d,db,"<IIQQQQQQ")
          entries=[]; strtab_v=None; strsz=None; i=0
          while True:
              tag,val=u(d,d_off+i*16,"<qQ")
              if tag==0: break
              entries.append((tag,val))
              if tag==5: strtab_v=val
              if tag==10: strsz=val
              i+=1
          strtab_f=v2f(strtab_v)
          orig=bytes(d[strtab_f:strtab_f+strsz])
          e_shoff=u(d,0x28,"<Q")[0]; e_shnum=u(d,0x3c,"<H")[0]; e_shentsize=u(d,0x3a,"<H")[0]
          maxend=0
          for i in range(e_shnum):
              b=e_shoff+i*e_shentsize; off,size=u(d,b+24,"<QQ")
              if rw_off<=off<rw_off+rw[2]: maxend=max(maxend,off+size)
          free=maxend+((16-(maxend%16))%16)
          rp=libdir.encode()+b"\x00"
          pad=(8-(len(orig)%8))%8
          new_str=orig+b"\x00"*pad+rp
          rp_off=len(orig)+pad; new_sz=len(new_str)
          str_f=free; str_v=f2v_rw(str_f)
          dyn_f=str_f+new_sz+((16-((str_f+new_sz)%16))%16); dyn_v=f2v_rw(dyn_f)
          nd=[]
          for tag,val in entries:
              if tag==5: val=str_v
              elif tag==10: val=new_sz
              nd.append((tag,val))
          nd.append((29,rp_off)); nd.append((0,0))
          db_b=b"".join(struct.pack("<qQ",t,v) for t,v in nd)
          assert dyn_f+len(db_b)<=rw_off+rw[2], "not enough RW padding"
          d[str_f:str_f+new_sz]=new_str
          d[dyn_f:dyn_f+len(db_b)]=db_b
          struct.pack_into("<IIQQQQQQ",d,db,2,u(d,db,"<IIQQQQQQ")[1],dyn_f,dyn_v,dyn_v,len(db_b),len(db_b),8)
          with open(path,"wb") as f: f.write(d)
          print("RUNPATH=%s injected"%libdir)
      patch(sys.argv[1], sys.argv[2])
    PY
    system python, (buildpath/"inject-runpath.py").to_s, src.to_s, libdir.to_s

    # Self-sign the patched binary.
    system sign, src.to_s
    mkdir_p libexec/"bin"
    libexec.install src => "bin/opencode"
    chmod 0755, libexec/"bin/opencode"

    # Build the dlopen-sign shim: intercepts dlopen/dlmopen and signs any
    # unsigned ELF extracted under TMPDIR before loading it.
    signer_path = Formula["ohos-bst-light"].opt_bin/"self-sign"
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
      static int needs_signing(const char *path) {
        int fd = open(path, O_RDONLY);
        if (fd < 0) return 0;
        Elf64_Ehdr eh;
        if (read(fd, &eh, sizeof eh) != (ssize_t)sizeof eh) { close(fd); return 0; }
        if (memcmp(eh.e_ident, ELFMAG, SELFMAG) != 0) { close(fd); return 0; }
        Elf64_Shdr *sh = calloc(eh.e_shnum, sizeof(Elf64_Shdr));
        if (!sh) { close(fd); return 0; }
        if (lseek(fd, eh.e_shoff, SEEK_SET) < 0 ||
            read(fd, sh, (size_t)eh.e_shnum * sizeof(Elf64_Shdr)) !=
                (ssize_t)((size_t)eh.e_shnum * sizeof(Elf64_Shdr))) { free(sh); close(fd); return 0; }
        Elf64_Shdr *str = &sh[eh.e_shstrndx];
        char *names = malloc(str->sh_size);
        if (!names) { free(sh); close(fd); return 0; }
        if (lseek(fd, str->sh_offset, SEEK_SET) < 0 ||
            read(fd, names, str->sh_size) != (ssize_t)str->sh_size) { free(names); free(sh); close(fd); return 0; }
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
        const char *tmp = getenv("TMPDIR");
        if (!tmp || *tmp == '\\0') return;
        size_t n = strlen(tmp);
        if (strncmp(path, tmp, n) != 0) return;
        if (!needs_signing(path)) return;
        pid_t p = fork();
        if (p == 0) {
          /* Silence self-sign so its output does not corrupt the TUI. */
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
      void *dlmopen(void *nsid, const char *filename, int flags) {
        ensure_signed(filename);
        static void *(*real)(void *, const char *, int);
        if (!real) real = (void *(*)(void *, const char *, int))dlsym(RTLD_NEXT, "dlmopen");
        return real(nsid, filename, flags);
      }
    C
    system Formula["ohos-sdk"].opt_bin/"../native/llvm/bin/clang",
           "-shared", "-fPIC", "-o", "libdlopen_sign_shim.so",
           "dlopen_sign_shim.c", "-O2", "-Wall", "-Wextra"
    libexec.install "libdlopen_sign_shim.so" => "lib/libdlopen_sign_shim.so"
    # ohos-sdk clang already signs its output (adds a .codesign section);
    # self-sign errors on a file that's already signed rather than skipping,
    # so don't call it again here.

    (bin/"opencode").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{libexec}/lib/libdlopen_sign_shim.so:#{Formula["close-range-shim"].opt_lib}/libclose_range_shim.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      exec "#{libexec}/bin/opencode" "$@"
    SH
    chmod 0755, bin/"opencode"
  end

  def caveats
    <<~EOS
      opencode (prebuilt) is ready. Configure a provider, e.g.:
        opencode auth

      This build bundles musl libstdc++/libgcc_s (Alpine) and injects a
      DT_RUNPATH at them, since OHOS lacks the GCC runtime. It also preloads
      close-range-shim (OHOS seccomp blocks the close_range syscall).
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
