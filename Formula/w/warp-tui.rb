class WarpTui < Formula
  desc "Warp Agent CLI — non-GUI terminal agent TUI, HarmonyOS aarch64, from source"
  homepage "https://www.warp.dev"
  # warp is a live monorepo with no stable version tags for the OSS TUI
  # target (the whole app/warpui_core/warpui workspace ships as one repo,
  # versioned internally by Warp's own release pipeline, not git tags).
  # Same shape as opencode@2.rb / zellij.rb: pin a git revision, keep
  # `version` a human-readable, non-semantic label. warp-tui-oss --version
  # itself prints "v0.0.0.0.0.0" (a build-system placeholder upstream never
  # replaces for OSS/local builds), so "0.0.0-dev" mirrors that rather than
  # inventing a version number that doesn't exist anywhere upstream.
  url "https://github.com/warpdotdev/warp.git",
      revision: "06e4b74a430b17461b7a1e251359ffd85e713c6b", branch: "master"
  version "0.0.0-dev"
  # AGPL-3.0 for the app/warp_tui crates built here; warpui_core/warpui
  # (not built into this binary target) are MIT. See the Corresponding
  # Source note in `caveats` below.
  license "AGPL-3.0-only"

  livecheck do
    url "https://api.github.com/repos/warpdotdev/warp/commits?sha=master&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/warp-tui-v0.0.0-dev-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  end

  depends_on "cmake" => :build
  depends_on "jq" => :build
  depends_on "musl-compat" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "protobuf" => :build
  depends_on "rust" => :build
  depends_on "bzip2"
  depends_on "ohos-compat-shim"
  depends_on "openssl@3"
  depends_on "xz"
  depends_on "zlib"

  # All OHOS source adaptations are done via inreplace in install() — zero
  # .patch files, per this tap's single-file-self-contained convention
  # (Patches/llvm@21/ is legacy; new formulae don't get a Patches/ dir).
  # This is also how AGPL §6's "Corresponding Source" obligation for our
  # modifications gets satisfied without a separate publication step: the
  # unmodified upstream source is already public at the pinned revision
  # above, and every byte we changed on top of it is spelled out below, in
  # this same file, which lives in the public social4hyq/homebrew-core repo.
  #
  # Full investigation trail (why each patch exists, what was tried and
  # ruled out, real-device verification) is written up at
  # https://github.com/social4hyq/homebrew-core — see this formula's PR
  # description and commit history; the short version is inline as comments
  # below at each patch site.
  def install
    # aws-lc-sys (pulled in via rustls -> aws-lc-rs) only has real OHOS
    # support through its CMake builder path, which shells out to a bundled
    # ohos.toolchain.cmake under $OHOS_NDK_HOME/native. Same root cause and
    # fix as zellij.rb.
    ENV["OHOS_NDK_HOME"] = formula_opt_prefix("ohos-sdk")
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    # Some CI cmake wrappers resolve `dirname "$0"` against the invoking
    # symlink's directory rather than the real Cellar keg directory, which
    # breaks any build (aws-lc-sys among them) that shells out to `cmake` by
    # bare name through PATH. Point straight at the real binary if present;
    # a no-op once/if the cmake formula's own wrapper is fixed upstream.
    cmake_real = Pathname.glob(HOMEBREW_CELLAR/"cmake/*/bin/cmake.real").first
    ENV["CMAKE"] = cmake_real.to_s if cmake_real

    # --- musl-compat: OHOS's musl drops ~36 symbols relative to upstream
    # musl (qsort_r, mq_*, aio_*, pthread_cancel, etc.); several transitive
    # C dependencies (zstd-sys's dictBuilder, in particular) assume they
    # exist because they detect "Linux" and assume glibc-or-modern-musl.
    # -include this wrapper (not musl_compat.h directly) into every C
    # compilation unit so declarations are available without patching each
    # vendored C source individually.
    musl_compat_include = "#{formula_opt_prefix("musl-compat")}/include"
    wrapper = buildpath/"musl_compat_wrapper.h"
    wrapper.write <<~C
      #ifndef MUSL_COMPAT_WRAPPER_H
      #define MUSL_COMPAT_WRAPPER_H
      #ifndef __ASSEMBLER__
      /* musl_compat.h uses bare C99 `restrict`, which isn't a keyword in
       * C++ mode (some vendored .c files here get compiled via the C++
       * frontend); alias it to the GNU/Clang extension keyword just for
       * the duration of this include. Also: `-include` gets applied
       * unconditionally to every translation unit cc-rs hands to the
       * compiler, including assembler-with-cpp (.S) files, where the C
       * declarations below would be parsed as garbage instructions — the
       * __ASSEMBLER__ guard above (predefined by clang/gcc for those
       * units) makes this whole header a no-op for them. */
      #if defined(__cplusplus) && !defined(restrict)
      #define restrict __restrict
      #define MUSL_COMPAT_WRAPPER_UNDEF_RESTRICT 1
      #endif
      #include "musl_compat.h"
      #ifdef MUSL_COMPAT_WRAPPER_UNDEF_RESTRICT
      #undef restrict
      #undef MUSL_COMPAT_WRAPPER_UNDEF_RESTRICT
      #endif
      #endif
      #endif
    C

    # -D_GNU_SOURCE: OHOS's unistd.h gates getentropy() behind
    # _GNU_SOURCE/_BSD_SOURCE, not the _DEFAULT_SOURCE that aws-lc's own
    # getentropy.c defines (a reasonable assumption on stock musl/glibc,
    # just not what OHOS's fork actually requires).
    ohos_cflags = "-D_GNU_SOURCE -I#{musl_compat_include} -include #{wrapper}"
    ENV["CFLAGS_aarch64_unknown_linux_ohos"] = ohos_cflags
    ENV["CXXFLAGS_aarch64_unknown_linux_ohos"] = ohos_cflags

    # --- tls_key_shim: rustc itself (not the compiled program) aborts with
    # "fatal runtime error: out of TLS keys" partway through compiling the
    # `app` crate. Root cause (confirmed by disassembling the real
    # /lib/ld-musl-aarch64.so.1, not the ohos-sdk sysroot's link-time-only
    # stub .so): pthread_key_create masks its slot index with `& 0x7f`
    # against a fixed 128-slot array compiled into musl's data segment
    # (PTHREAD_KEYS_MAX = 128 vs glibc's 1024) — this crate's dependency
    # tree touches more than 128 distinct thread_local statics across
    # rustc + LLVM + the compiled code combined. Not fixable by any
    # compiler/linker flag or by reducing Cargo features (tried: trimming
    # ~200 enabled features down to the 4 warp_tui actually needs didn't
    # move the count enough).
    #
    # This shim reserves exactly one real musl pthread key and multiplexes
    # up to 8192 virtual keys on top of it via LD_PRELOAD symbol
    # interposition — same technique this tap already uses for
    # ohos-compat-shim/dlopen-sign-shim, just applied to rustc's own
    # process instead of to the final product. It's build-tooling only:
    # never linked into or shipped with warp-tui-oss itself.
    shim_src = buildpath/"tls_key_shim.c"
    shim_src.write <<~C
      #define _GNU_SOURCE
      #include <dlfcn.h>
      #include <pthread.h>
      #include <stdlib.h>

      #define VIRTUAL_KEYS_MAX 8192
      #define VIRTUAL_KEY_BASE 0x40000000u

      typedef void (*dtor_fn)(void *);

      typedef int (*key_create_fn)(pthread_key_t *, void (*)(void *));
      typedef int (*key_delete_fn)(pthread_key_t);
      typedef int (*setspecific_fn)(pthread_key_t, const void *);
      typedef void *(*getspecific_fn)(pthread_key_t);

      static key_create_fn real_pthread_key_create;
      static key_delete_fn real_pthread_key_delete;
      static setspecific_fn real_pthread_setspecific;
      static getspecific_fn real_pthread_getspecific;

      static pthread_once_t init_once = PTHREAD_ONCE_INIT;
      static pthread_key_t real_key;
      static int real_key_valid = 0;

      static pthread_mutex_t alloc_mutex = PTHREAD_MUTEX_INITIALIZER;
      static dtor_fn dtors[VIRTUAL_KEYS_MAX];
      static int slot_used[VIRTUAL_KEYS_MAX];

      typedef struct {
        void *values[VIRTUAL_KEYS_MAX];
      } per_thread_table;

      static void per_thread_table_destructor(void *arg) {
        per_thread_table *table = (per_thread_table *)arg;
        if (!table) {
          return;
        }
        for (int pass = 0; pass < 4; pass++) {
          int any = 0;
          for (int i = 0; i < VIRTUAL_KEYS_MAX; i++) {
            void *val = table->values[i];
            if (val && dtors[i]) {
              table->values[i] = NULL;
              dtors[i](val);
              any = 1;
            }
          }
          if (!any) {
            break;
          }
        }
        free(table);
      }

      static void init_shim(void) {
        real_pthread_key_create = (key_create_fn)dlsym(RTLD_NEXT, "pthread_key_create");
        real_pthread_key_delete = (key_delete_fn)dlsym(RTLD_NEXT, "pthread_key_delete");
        real_pthread_setspecific = (setspecific_fn)dlsym(RTLD_NEXT, "pthread_setspecific");
        real_pthread_getspecific = (getspecific_fn)dlsym(RTLD_NEXT, "pthread_getspecific");

        if (!real_pthread_key_create || !real_pthread_key_delete ||
            !real_pthread_setspecific || !real_pthread_getspecific) {
          return;
        }

        if (real_pthread_key_create(&real_key, per_thread_table_destructor) == 0) {
          real_key_valid = 1;
        }
      }

      static per_thread_table *get_table(int create) {
        if (!real_key_valid) {
          return NULL;
        }
        per_thread_table *table = (per_thread_table *)real_pthread_getspecific(real_key);
        if (!table && create) {
          table = calloc(1, sizeof(per_thread_table));
          if (table) {
            real_pthread_setspecific(real_key, table);
          }
        }
        return table;
      }

      static int decode_slot(pthread_key_t key, int *slot_out) {
        unsigned k = (unsigned)key;
        if (k < VIRTUAL_KEY_BASE) {
          return 0;
        }
        unsigned slot = k - VIRTUAL_KEY_BASE;
        if (slot >= VIRTUAL_KEYS_MAX) {
          return 0;
        }
        *slot_out = (int)slot;
        return 1;
      }

      int pthread_key_create(pthread_key_t *key, void (*destructor)(void *)) {
        pthread_once(&init_once, init_shim);

        if (!real_key_valid) {
          return real_pthread_key_create(key, destructor);
        }

        pthread_mutex_lock(&alloc_mutex);
        int slot = -1;
        for (int i = 0; i < VIRTUAL_KEYS_MAX; i++) {
          if (!slot_used[i]) {
            slot = i;
            break;
          }
        }
        if (slot >= 0) {
          slot_used[slot] = 1;
          dtors[slot] = destructor;
        }
        pthread_mutex_unlock(&alloc_mutex);

        if (slot < 0) {
          return 11; /* EAGAIN */
        }
        *key = (pthread_key_t)(VIRTUAL_KEY_BASE + (unsigned)slot);
        return 0;
      }

      int pthread_key_delete(pthread_key_t key) {
        pthread_once(&init_once, init_shim);
        int slot;
        if (!decode_slot(key, &slot)) {
          return real_pthread_key_delete(key);
        }
        pthread_mutex_lock(&alloc_mutex);
        slot_used[slot] = 0;
        dtors[slot] = NULL;
        pthread_mutex_unlock(&alloc_mutex);
        return 0;
      }

      int pthread_setspecific(pthread_key_t key, const void *value) {
        pthread_once(&init_once, init_shim);
        int slot;
        if (!decode_slot(key, &slot)) {
          return real_pthread_setspecific(key, value);
        }
        per_thread_table *table = get_table(1);
        if (!table) {
          return 12; /* ENOMEM */
        }
        table->values[slot] = (void *)value;
        return 0;
      }

      void *pthread_getspecific(pthread_key_t key) {
        pthread_once(&init_once, init_shim);
        int slot;
        if (!decode_slot(key, &slot)) {
          return real_pthread_getspecific(key);
        }
        per_thread_table *table = get_table(0);
        if (!table) {
          return NULL;
        }
        return table->values[slot];
      }
    C
    system ENV.cc, "-shared", "-fPIC", "-O2", "-o", "tls_key_shim.so", "tls_key_shim.c", "-ldl"
    # Build-time only: preloaded for the duration of `cargo build` below,
    # never written into the wrapper script that ships to users.
    ENV["LD_PRELOAD"] = (buildpath/"tls_key_shim.so").to_s

    # --- Source patches (all in-formula inreplace, see comment above
    # install()). Each site below mirrors a real compile error hit against
    # upstream, verified end to end (cargo check + cargo build +
    # `--help`/`--version` on both the OHOS CI container and a real
    # HarmonyOS device).

    # 0. Workspace-wide nix version bump: 0.26.4 (upstream's pin) has no
    # OHOS support at all (no `target_env = "ohos"` branches anywhere in
    # its own sys/statfs.rs etc.); 0.31+ added it. This one-line bump is
    # what actually *requires* the fd-API migration patches further below
    # — nix 0.26 used raw RawFd/i32 everywhere, 0.31 moved to the
    # AsFd/OwnedFd/BorrowedFd I/O-safety types the whole Rust ecosystem
    # adopted around 2023, and Warp's own terminal code predates that
    # migration. A third-party dependency (`pprof`, pulled in only via the
    # optional, not-enabled-here `pprof_cpu_profiling` feature) hard-pins
    # `nix = "0.26"` in its own Cargo.toml; Cargo resolves that as an
    # independent semver-incompatible 0.x line coexisting with our 0.31 in
    # the same lockfile rather than a conflict, since nothing in this
    # build ever enables that feature.
    inreplace "Cargo.toml" do |s|
      s.sub!(
        "nix = { version = \"0.26.4\", default-features = false, features = [\"signal\"] }",
        "nix = { version = \"0.31\", default-features = false, features = [\"signal\"] }",
      ) || odie("warp-tui: workspace Cargo.toml nix version anchor not found")
    end

    # 1. freedesktop-desktop-entry: pulls in gettext-sys -> a vendored
    # gnulib snapshot that hardcodes `NSIG <= 32`, which OHOS's 65-signal
    # NSIG violates at compile time. This dependency exists purely to
    # detect installed GUI text editors via .desktop files — meaningless
    # for a TUI-only build — so it's excluded for this target instead of
    # patched.
    inreplace "app/Cargo.toml" do |s|
      s.sub!(
        "[target.'cfg(any(target_os = \"linux\", target_os = \"freebsd\"))'.dependencies]\n" \
        "freedesktop-desktop-entry = \"0.5.0\"\n" \
        "x11rb.workspace = true\n" \
        "zbus.workspace = true",
        "[target.'cfg(all(any(target_os = \"linux\", target_os = \"freebsd\"), " \
        "not(target_env = \"ohos\")))'.dependencies]\n" \
        "freedesktop-desktop-entry = \"0.5.0\"\n\n" \
        "[target.'cfg(any(target_os = \"linux\", target_os = \"freebsd\"))'.dependencies]\n" \
        "x11rb.workspace = true\n" \
        "zbus.workspace = true",
      ) || odie("warp-tui: app/Cargo.toml freedesktop-desktop-entry anchor not found")
    end

    # 2. external_editor: the platform module that calls into
    # freedesktop-desktop-entry (excluded above) needs a matching OHOS
    # exclusion plus a stub implementation of the one method
    # (`Editor::is_installed`) a non-platform-gated caller still invokes.
    inreplace "app/src/util/file/external_editor/mod.rs" do |s|
      s.sub!(
        "#[cfg(any(target_os = \"linux\", target_os = \"freebsd\"))]\nmod linux;",
        "#[cfg(all(any(target_os = \"linux\", target_os = \"freebsd\"), " \
        "not(target_env = \"ohos\")))]\nmod linux;",
      ) || odie("warp-tui: external_editor/mod.rs mod-linux anchor not found")
      s.sub!(
        "} else if #[cfg(any(target_os = \"linux\", target_os = \"freebsd\"))] {\n            " \
        "linux::open_file_path_with_line_and_col(line_column_number, editor, &full_path, ctx);",
        "} else if #[cfg(all(any(target_os = \"linux\", target_os = \"freebsd\"), " \
        "not(target_env = \"ohos\")))] {\n            " \
        "linux::open_file_path_with_line_and_col(line_column_number, editor, &full_path, ctx);",
      ) || odie("warp-tui: external_editor/mod.rs cfg_if anchor not found")
      s.sub!(
        "use warpui::{AppContext, SingletonEntity};\n",
        "use warpui::{AppContext, SingletonEntity};\n\n" \
        "// OHOS has no desktop-entry (.desktop file) mechanism to detect installed\n" \
        "// GUI editors, so `linux` is excluded above for this target; provide the\n" \
        "// `Editor::is_installed` method here instead of in a platform module, since\n" \
        "// there's no `.desktop`-based detection to perform.\n" \
        "#[cfg(target_env = \"ohos\")]\n" \
        "impl Editor {\n    " \
        "pub fn is_installed(&self, _ctx: &mut AppContext) -> bool {\n        " \
        "false\n    " \
        "}\n" \
        "}\n",
      ) || odie("warp-tui: external_editor/mod.rs import anchor not found")
    end

    # 3. warp_tui's own Cargo.toml: `warp = { workspace = true, ... }` can't
    # have `default-features = false` added locally (Cargo forbids
    # overriding default-features on a workspace-inherited dependency), so
    # switch to an equivalent direct path dependency. Without this, the
    # `app` crate's ~200 product feature flags (billing pages, agent-mode
    # variants, etc.) all compile in — none of them are needed for the TUI,
    # and they widen the codebase enough to make the TLS-key-shim's margin
    # tighter than it needs to be.
    inreplace "crates/warp_tui/Cargo.toml" do |s|
      s.sub!(
        "warp = { workspace = true, features = [\n  " \
        "\"image_as_context\",\n  " \
        "\"nld_classifier_v3\",\n  " \
        "\"nld_heuristic_v2\",\n  " \
        "\"tui\",\n" \
        "] }",
        "warp = { path = \"../../app\", default-features = false, features = [\n  " \
        "\"image_as_context\",\n  " \
        "\"nld_classifier_v3\",\n  " \
        "\"nld_heuristic_v2\",\n  " \
        "\"tui\",\n" \
        "] }",
      ) || odie("warp-tui: crates/warp_tui/Cargo.toml warp-dependency anchor not found")
    end

    # 4-9. nix 0.26 -> 0.31 fd-safety API migration (AsFd/OwnedFd/
    # BorrowedFd), across the terminal-server and kitty-graphics-protocol
    # code. Warp's own code predates this Rust-ecosystem-wide migration;
    # OHOS's `nix` support only landed in 0.31+ (pprof's own `nix = "0.26"`
    # pin coexists fine — Cargo allows multiple semver-incompatible 0.x
    # lines of the same crate side by side). Each site below preserves the
    # *original* fd-ownership intent: `.into_raw_fd()` where the code
    # already manually dup2'd/closed the fd (transferring ownership out of
    # Rust's RAII so the manual bookkeeping keeps working unchanged), vs
    # `BorrowedFd::borrow_raw()` where the code only ever peeked at a fd
    # someone else owns. Mixing these up risks a double-close (the OwnedFd
    # auto-closing a fd the code also closes manually) — verified against
    # both classes with a standalone correctness pass before folding into
    # this formula, not applied mechanically off the compiler's own
    # suggestions.

    # 4a. local_tty/server/mod.rs: reorder so the CLOEXEC fcntl calls (which
    # only need a borrowed view) run before the fd handoff to the receiver
    # thread (which takes ownership) — OwnedFd isn't Copy like the old
    # RawFd was, so the original ordering would now be a use-after-move.
    inreplace "app/src/terminal/local_tty/server/mod.rs" do |s|
      s.sub!(
        "        // Create a concurrency-safe set to track the list of terminated\n        " \
        "// children that the terminal server has notified us about but\n        " \
        "// the pty event loops haven't yet processed.\n        " \
        "let terminated_children = Arc::new(Mutex::new(HashSet::new()));\n\n        " \
        "// Spawn the message receiver background thread.\n        " \
        "spawn_message_receiver_thread(client_recv_fd, terminated_children.clone());\n\n        " \
        "unsafe {\n            " \
        "// Make sure the client file descriptor is closed when the server process\n            " \
        "// is executed (as it only needs the server side of the socket pair).\n            " \
        "cvt(libc::fcntl(client_send_fd, libc::F_SETFD, libc::FD_CLOEXEC))\n                " \
        ".context(\"Failed to set CLOEXEC flag on client fd before fork\")?;\n            " \
        "cvt(libc::fcntl(client_recv_fd, libc::F_SETFD, libc::FD_CLOEXEC))\n                " \
        ".context(\"Failed to set CLOEXEC flag on client fd before fork\")?;\n\n            " \
        "let program = std::env::current_exe()",
        "        // Create a concurrency-safe set to track the list of terminated\n        " \
        "// children that the terminal server has notified us about but\n        " \
        "// the pty event loops haven't yet processed.\n        " \
        "let terminated_children = Arc::new(Mutex::new(HashSet::new()));\n\n        " \
        "unsafe {\n            " \
        "// Make sure the client file descriptor is closed when the server process\n            " \
        "// is executed (as it only needs the server side of the socket pair).\n            " \
        "cvt(libc::fcntl(\n                " \
        "client_send_fd.as_raw_fd(),\n                " \
        "libc::F_SETFD,\n                " \
        "libc::FD_CLOEXEC,\n            " \
        "))\n            " \
        ".context(\"Failed to set CLOEXEC flag on client fd before fork\")?;\n            " \
        "cvt(libc::fcntl(\n                " \
        "client_recv_fd.as_raw_fd(),\n                " \
        "libc::F_SETFD,\n                " \
        "libc::FD_CLOEXEC,\n            " \
        "))\n            " \
        ".context(\"Failed to set CLOEXEC flag on client fd before fork\")?;\n\n            " \
        "// Spawn the message receiver background thread. It takes\n            " \
        "// ownership of `client_recv_fd` for the remaining lifetime of\n            " \
        "// the process (the thread never explicitly closes it).\n            " \
        "spawn_message_receiver_thread(client_recv_fd.into_raw_fd(), terminated_children.clone());\n\n            " \
        "// `server_recv_fd`/`server_send_fd` are managed manually from\n            " \
        "// here on (dup2'd into fixed slots in the child process, then\n            " \
        "// closed here in the parent), so convert them to raw fds now.\n            " \
        "let server_recv_fd = server_recv_fd.into_raw_fd();\n            " \
        "let server_send_fd = server_send_fd.into_raw_fd();\n\n            " \
        "let program = std::env::current_exe()",
      ) || odie("warp-tui: server/mod.rs socketpair-ownership anchor not found")
      s.sub!(
        "            let client = Arc::new(TerminalServerClient::new(\n                " \
        "OwnedFd::from_raw_fd(client_send_fd),\n                " \
        "terminated_children,\n            " \
        "));",
        "            let client = Arc::new(TerminalServerClient::new(\n                " \
        "client_send_fd,\n                " \
        "terminated_children,\n            " \
        "));",
      ) || odie("warp-tui: server/mod.rs TerminalServerClient::new anchor not found")
    end

    # 4b. local_tty/server/event_loop.rs: RECV_SOCKET_FILENO/SEND_SOCKET_FILENO
    # are fixed fd numbers the parent dup2'd into place, not values Rust
    # owns — nix::fcntl::fcntl now requires AsFd, so wrap them as borrows.
    inreplace "app/src/terminal/local_tty/server/event_loop.rs" do |s|
      s.sub!(
        "        fcntl::fcntl(RECV_SOCKET_FILENO, fcntl::F_GETFD)\n            " \
        ".expect(\"should have valid file descriptor\");\n        " \
        "fcntl::fcntl(\n            " \
        "RECV_SOCKET_FILENO,\n            " \
        "fcntl::F_SETFD(fcntl::FdFlag::FD_CLOEXEC),\n        " \
        ")\n        " \
        ".expect(\"should be able to set FD_CLOEXEC on unix socket\");\n\n        " \
        "fcntl::fcntl(SEND_SOCKET_FILENO, fcntl::F_GETFD)\n            " \
        ".expect(\"should have valid file descriptor\");\n        " \
        "fcntl::fcntl(\n            " \
        "SEND_SOCKET_FILENO,\n            " \
        "fcntl::F_SETFD(fcntl::FdFlag::FD_CLOEXEC),\n        " \
        ")\n        " \
        ".expect(\"should be able to set FD_CLOEXEC on unix socket\");",
        "        // SAFETY: RECV_SOCKET_FILENO/SEND_SOCKET_FILENO are well-known fd\n        " \
        "// numbers that the parent process dup2'd into place before exec'ing\n        " \
        "// this process; they are valid for the remainder of this process's\n        " \
        "// lifetime and are not owned/closed via Rust's fd ownership types.\n        " \
        "let recv_socket_borrowed_fd = unsafe { BorrowedFd::borrow_raw(RECV_SOCKET_FILENO) };\n        " \
        "let send_socket_borrowed_fd = unsafe { BorrowedFd::borrow_raw(SEND_SOCKET_FILENO) };\n\n        " \
        "fcntl::fcntl(recv_socket_borrowed_fd, fcntl::F_GETFD)\n            " \
        ".expect(\"should have valid file descriptor\");\n        " \
        "fcntl::fcntl(\n            " \
        "recv_socket_borrowed_fd,\n            " \
        "fcntl::F_SETFD(fcntl::FdFlag::FD_CLOEXEC),\n        " \
        ")\n        " \
        ".expect(\"should be able to set FD_CLOEXEC on unix socket\");\n\n        " \
        "fcntl::fcntl(send_socket_borrowed_fd, fcntl::F_GETFD)\n            " \
        ".expect(\"should have valid file descriptor\");\n        " \
        "fcntl::fcntl(\n            " \
        "send_socket_borrowed_fd,\n            " \
        "fcntl::F_SETFD(fcntl::FdFlag::FD_CLOEXEC),\n        " \
        ")\n        " \
        ".expect(\"should be able to set FD_CLOEXEC on unix socket\");",
      ) || odie("warp-tui: event_loop.rs fcntl anchor not found")
    end

    # 4c. local_tty/server/protocol.rs: same borrow-not-own pattern for
    # NonblockingSocketFd::new's fd param; plus nix::sys::socket::RecvMsg's
    # cmsgs() now returns Result<CmsgIterator, Errno> instead of the
    # iterator directly.
    inreplace "app/src/terminal/local_tty/server/protocol.rs" do |s|
      s.sub!(
        "    pub fn new(fd: RawFd) -> Result<Self> {\n        " \
        "use nix::fcntl;\n\n        " \
        "let mut flags = fcntl::OFlag::from_bits(\n            " \
        "fcntl::fcntl(fd, fcntl::F_GETFL)\n                " \
        ".context(\"should be able to read flags from unix socket\")?,\n        " \
        ")\n        " \
        ".ok_or_else(|| anyhow!(\"received invalid flags from fcntl F_GETFL\"))?;\n        " \
        "flags.insert(fcntl::OFlag::O_NONBLOCK);\n        " \
        "fcntl::fcntl(fd, fcntl::F_SETFL(flags))\n            " \
        ".context(\"should be able to set O_NONBLOCK on unix socket\")?;\n\n        " \
        "Ok(Self(fd))\n    " \
        "}",
        "    pub fn new(fd: RawFd) -> Result<Self> {\n        " \
        "use nix::fcntl;\n\n        " \
        "// SAFETY: `fd` is a well-known fd number owned/closed elsewhere (see\n        " \
        "// callers); we only need a borrowed view to query/set its flags.\n        " \
        "let borrowed_fd = unsafe { BorrowedFd::borrow_raw(fd) };\n\n        " \
        "let mut flags = fcntl::OFlag::from_bits(\n            " \
        "fcntl::fcntl(borrowed_fd, fcntl::F_GETFL)\n                " \
        ".context(\"should be able to read flags from unix socket\")?,\n        " \
        ")\n        " \
        ".ok_or_else(|| anyhow!(\"received invalid flags from fcntl F_GETFL\"))?;\n        " \
        "flags.insert(fcntl::OFlag::O_NONBLOCK);\n        " \
        "fcntl::fcntl(borrowed_fd, fcntl::F_SETFL(flags))\n            " \
        ".context(\"should be able to set O_NONBLOCK on unix socket\")?;\n\n        " \
        "Ok(Self(fd))\n    " \
        "}",
      ) || odie("warp-tui: protocol.rs NonblockingSocketFd::new anchor not found")
      s.sub!(
        "let cmsgs = msg.cmsgs().collect_vec();",
        "let cmsgs = msg.cmsgs()?.collect_vec();",
      ) || odie("warp-tui: protocol.rs cmsgs() anchor not found")
    end

    # 4d. local_tty/unix.rs: openpty() now returns OwnedFd master/slave
    # fields; make_pty()'s own contract is `-> Result<(RawFd, RawFd)>`
    # (these fds get dup2'd into a forked child, classic manual-lifetime
    # management), so take ownership out immediately. tcgetattr/tcsetattr
    # further down only need a borrow of the already-raw `leader`.
    inreplace "app/src/terminal/local_tty/unix.rs" do |s|
      s.sub!(
        "use std::os::unix::io::{AsRawFd, FromRawFd, RawFd};",
        "use std::os::fd::BorrowedFd;\nuse std::os::unix::io::{AsRawFd, FromRawFd, IntoRawFd, RawFd};",
      ) || odie("warp-tui: unix.rs import anchor not found")
      s.sub!(
        "    let ends = openpty(Some(&win_size), None).context(\"openpty failed\")?;\n    " \
        "// Configure the two new file descriptors to be closed on exec.  This keeps\n    " \
        "// us from leaking tty fds into spawned shells.  FD_CLOEXEC is _not_ shared\n    " \
        "// across duplicated fds, so when we call `libc::dup2()` below, those fds\n    " \
        "// will _not_ be closed when we exec the shell.\n    " \
        "unsafe {\n        " \
        "libc::fcntl(ends.master, libc::F_SETFD, libc::FD_CLOEXEC);\n        " \
        "libc::fcntl(ends.slave, libc::F_SETFD, libc::FD_CLOEXEC);\n    " \
        "}\n\n    " \
        "Ok((ends.master, ends.slave))",
        "    let ends = openpty(Some(&win_size), None).context(\"openpty failed\")?;\n    " \
        "// This function hands back raw, manually-managed fds (they get dup2'd\n    " \
        "// into a child process later), so take ownership out of the OwnedFds\n    " \
        "// openpty returns.\n    " \
        "let master = ends.master.into_raw_fd();\n    " \
        "let slave = ends.slave.into_raw_fd();\n    " \
        "// Configure the two new file descriptors to be closed on exec.  This keeps\n    " \
        "// us from leaking tty fds into spawned shells.  FD_CLOEXEC is _not_ shared\n    " \
        "// across duplicated fds, so when we call `libc::dup2()` below, those fds\n    " \
        "// will _not_ be closed when we exec the shell.\n    " \
        "unsafe {\n        " \
        "libc::fcntl(master, libc::F_SETFD, libc::FD_CLOEXEC);\n        " \
        "libc::fcntl(slave, libc::F_SETFD, libc::FD_CLOEXEC);\n    " \
        "}\n\n    " \
        "Ok((master, slave))",
      ) || odie("warp-tui: unix.rs make_pty anchor not found")
      s.sub!(
        "    #[cfg(any(target_os = \"linux\", target_os = \"macos\"))]\n    " \
        "if let Ok(mut termios) = termios::tcgetattr(leader) {\n        " \
        "// Set character encoding to UTF-8.\n        " \
        "termios.input_flags.set(InputFlags::IUTF8, true);\n        " \
        "let _ = termios::tcsetattr(leader, SetArg::TCSANOW, &termios);\n    " \
        "}",
        "    // SAFETY: `leader` remains a valid, open fd for the duration of this\n    " \
        "// block (it's only closed later, further down this function).\n    " \
        "#[cfg(any(target_os = \"linux\", target_os = \"macos\"))]\n    " \
        "if let Ok(mut termios) = termios::tcgetattr(unsafe { BorrowedFd::borrow_raw(leader) }) {\n        " \
        "// Set character encoding to UTF-8.\n        " \
        "termios.input_flags.set(InputFlags::IUTF8, true);\n        " \
        "let _ = termios::tcsetattr(\n            " \
        "unsafe { BorrowedFd::borrow_raw(leader) },\n            " \
        "SetArg::TCSANOW,\n            " \
        "&termios,\n        " \
        ");\n    " \
        "}",
      ) || odie("warp-tui: unix.rs tcgetattr anchor not found")
    end

    # 4e. local_tty/terminal_attributes.rs: same borrow pattern for a
    # struct-stored fd it doesn't own.
    inreplace "app/src/terminal/local_tty/terminal_attributes.rs" do |s|
      s.sub!(
        "use std::os::fd::RawFd;",
        "use std::os::fd::{BorrowedFd, RawFd};",
      ) || odie("warp-tui: terminal_attributes.rs import anchor not found")
      s.sub!(
        "fn fetch_termial_attributes(fd: RawFd) -> Result<Termios> {\n    " \
        "termios::tcgetattr(fd)\n" \
        "}",
        "fn fetch_termial_attributes(fd: RawFd) -> Result<Termios> {\n    " \
        "// SAFETY: `fd` is owned/closed elsewhere; this only needs a borrowed\n    " \
        "// view for the duration of the tcgetattr call.\n    " \
        "termios::tcgetattr(unsafe { BorrowedFd::borrow_raw(fd) })\n" \
        "}",
      ) || odie("warp-tui: terminal_attributes.rs tcgetattr anchor not found")
    end

    # 4f. terminal/model/kitty.rs: shm_open() now returns OwnedFd. Unlike
    # the other sites, the original code never explicitly closed this fd
    # after mmap'ing it (a pre-existing, mild leak) — letting it stay an
    # OwnedFd and drop naturally when the function returns is strictly
    # better than reproducing that leak, not a behavior change worth
    # avoiding. mmap()'s return type also changed from `*mut c_void` to
    # `NonNull<c_void>`.
    inreplace "app/src/terminal/model/kitty.rs" do |s|
      s.sub!(
        "fn read_from_shared_memory_fd(\n    " \
        "fd: i32,\n    " \
        "size: Option<usize>,\n" \
        ") -> Result<Vec<u8>, InvalidKittyPayload> {\n    " \
        "use std::num::NonZero;\n\n    " \
        "use nix::sys::mman::{MapFlags, ProtFlags, mmap};\n    " \
        "use nix::sys::stat::fstat;\n\n    " \
        "let file_size = match fstat(fd) {",
        "fn read_from_shared_memory_fd(\n    " \
        "fd: std::os::fd::OwnedFd,\n    " \
        "size: Option<usize>,\n" \
        ") -> Result<Vec<u8>, InvalidKittyPayload> {\n    " \
        "use std::num::NonZero;\n\n    " \
        "use nix::sys::mman::{MapFlags, ProtFlags, mmap};\n    " \
        "use nix::sys::stat::fstat;\n\n    " \
        "let file_size = match fstat(&fd) {",
      ) || odie("warp-tui: kitty.rs read_from_shared_memory_fd signature anchor not found")
      s.sub!(
        "    let ptr = unsafe {\n        " \
        "mmap(\n            " \
        "None,\n            " \
        "size,\n            " \
        "ProtFlags::PROT_READ,\n            " \
        "MapFlags::MAP_SHARED,\n            " \
        "fd,\n            " \
        "0,\n        " \
        ")\n    " \
        "};\n\n    " \
        "let Ok(ptr) = ptr else {\n        " \
        "return Err(InvalidKittyPayload::ShmError(ShmError::MmapError));\n    " \
        "};\n\n    " \
        "let slice = unsafe { std::slice::from_raw_parts(ptr as *const u8, size.into()) };",
        "    let ptr = unsafe {\n        " \
        "mmap(\n            " \
        "None,\n            " \
        "size,\n            " \
        "ProtFlags::PROT_READ,\n            " \
        "MapFlags::MAP_SHARED,\n            " \
        "&fd,\n            " \
        "0,\n        " \
        ")\n    " \
        "};\n\n    " \
        "let Ok(ptr) = ptr else {\n        " \
        "return Err(InvalidKittyPayload::ShmError(ShmError::MmapError));\n    " \
        "};\n\n    " \
        "let slice = unsafe { std::slice::from_raw_parts(ptr.as_ptr() as *const u8, size.into()) };",
      ) || odie("warp-tui: kitty.rs mmap anchor not found")
    end

    # 4g. crates/mcp/src/runtime.rs: `server_info.map(|info| &info.capabilities)`
    # takes `server_info: Option<ServerInfo>` *by value* into the closure,
    # then tries to return a reference into that now-closure-local `info` —
    # a real dangling-reference bug (E0515), not an OHOS-specific issue.
    # Only surfaces with this formula's `default-features = false` patch to
    # warp_tui's `warp` dependency (patch #3 above): upstream's default
    # feature set pulls in a `mcp` build configuration where this exact
    # function isn't part of the compiled closure graph the same way, so
    # nothing upstream ever forces rustc to typecheck this call shape.
    # `.as_ref()` first borrows the outer `server_info` (which outlives the
    # closure) instead of moving it in, matching what the callee
    # (`query_resources_for`/`query_tools_for`) already declares:
    # `capabilities: Option<&rmcp::model::ServerCapabilities>`.
    inreplace "crates/mcp/src/runtime.rs" do |s|
      s.sub!(
        "let capabilities = server_info.map(|info| &info.capabilities);",
        "let capabilities = server_info.as_ref().map(|info| &info.capabilities);",
      ) || odie("warp-tui: mcp/runtime.rs capabilities anchor not found")
    end

    # interprocess crate's own build.rs detects Unix-domain-socket support
    # via a hardcoded target_env allowlist (gnu/musl/musleabi/musleabihf)
    # that doesn't include "ohos", even though OHOS's musl fully supports
    # everything that list is checking for. These are exactly the cfgs its
    # build.rs would emit for a "linux + musl-family" target if "ohos" were
    # in that list — supplied externally via RUSTFLAGS since this is a
    # build.rs detection gap, not something a source patch to interprocess
    # itself would be proportionate to carry here.
    musl_compat_lib = "#{formula_opt_prefix("musl-compat")}/lib"
    uds_cfgs = %w[
      uds_sockaddr_un_len_108 uds_ucred uds_scm_credentials uds_peercred
      uds_msghdr_iovlen_c_int uds_msghdr_controllen_socklen_t
      uds_linux_namespace uds_scm_rights uds_ancillary_unsound uds_supported
    ].map { |cfg| "--cfg #{cfg}" }.join(" ")
    ENV["RUSTFLAGS"] = "-L #{musl_compat_lib} -l static=musl_compat #{uds_cfgs}"

    # release-tui's default profile keeps thin LTO but bumps codegen-units
    # from 1 to 16: confirmed on real GitHub-hosted ubuntu-24.04-arm CI
    # (bottle-build.yml run 31289028724) that codegen-units=1 gets SIGKILL'd
    # (OOM) while linking the final warp-tui-oss binary. codegen-units=16
    # was verified in the local-container spike to fit under 16GB peak RSS
    # without disabling LTO entirely, so it's the smallest change that
    # avoids the OOM.
    ENV["CARGO_PROFILE_RELEASE_TUI_CODEGEN_UNITS"] = "16"

    # Not std_cargo_args: that helper hardcodes --locked, which this build
    # can't use (the nix-version-bump patch above changes what the
    # workspace's Cargo.toml requires, so Cargo.lock must be allowed to
    # re-resolve); it also has no way to select --profile/--bin/a specific
    # workspace member. --root libexec lands the binary at exactly
    # libexec/bin/warp-tui-oss, same layout the wrapper below expects.
    system "cargo", "install", "--profile", "release-tui", "--path", "crates/warp_tui",
           "--bin", "warp-tui-oss", "--features", "standalone", "--root", libexec

    (bin/"warp-tui-oss").write <<~SH
      #!/bin/sh
      export TMPDIR="${TMPDIR:-/data/storage/el2/base/tmp}"
      export LD_PRELOAD="#{formula_opt_prefix("ohos-compat-shim")}/lib/libohos_compat.so${LD_PRELOAD:+:$LD_PRELOAD}"
      exec "#{opt_libexec}/bin/warp-tui-oss" "$@"
    SH
    chmod 0755, bin/"warp-tui-oss"
  end

  def caveats
    <<~CAVEATS
      This build is licensed AGPL-3.0-only, matching upstream warpdotdev/warp
      (the `warpui_core`/`warpui` crates are MIT but are not part of this
      TUI-only binary target). The unmodified upstream source is public at
      the pinned commit in this formula's `url`; every modification made on
      top of it for OHOS is spelled out inline in this formula's own
      source, which is itself public in this tap.

      Agent conversations require a Warp account or API key:
        warp-tui-oss --set-provider-api-key <openai|anthropic|google|grok>
      See `warp-tui-oss --help` for the full option list.

      local_tty's PTY session handling forks the current binary and execs
      it again as a "terminal server" child process — the same fork+
      pre_exec pattern that needs ohos-compat-shim's `close_range`/
      `getcwd` interception on other formulae in this tap (zellij, herdr).
      The wrapper already preloads it; do not strip that out.
    CAVEATS
  end

  test do
    assert_match "warp-tui-oss", shell_output("#{bin}/warp-tui-oss --help")
    assert_match "--resume", shell_output("#{bin}/warp-tui-oss --help")
  end
end
