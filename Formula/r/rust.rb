class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"
  license any_of: ["Apache-2.0", "MIT"]
  revision 2
  compatibility_version 1
  head "https://github.com/rust-lang/rust.git", branch: "main"

  stable do
    url "https://static.rust-lang.org/dist/rustc-1.98.1-src.tar.gz"
    sha256 "dc9f8b917b32444d6c7ac43cc1b409013d3a9a633338bb60c14cdae1d15ee65a"

    # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0
    # HEAD does not use these as it needs a nightly rust
    resource "rustc-bootstrap" do
      on_macos do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/rustc-1.97.1-aarch64-apple-darwin.tar.xz", using: :nounzip
          sha256 "6076cad38ccabaa24325f26a74080a363a2633a9cd34c473a8977255d8a593cb"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/rustc-1.97.1-x86_64-apple-darwin.tar.xz", using: :nounzip
          sha256 "3c38289f319bf02fa1c8149ce3e00f261e4efd14813a99f7f7ae4f180c7d1173"
        end
      end

      on_linux do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/rustc-1.97.1-aarch64-unknown-linux-ohos.tar.xz", using: :nounzip
          sha256 "ebf18fb6e7b6e406c5ad70635fbc80d73ccec9bb34ea960d7bb5b2e8d2609379"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/rustc-1.97.1-x86_64-unknown-linux-gnu.tar.xz", using: :nounzip
          sha256 "9819d0a32d56bd339585319c80260e332779f5541fd66838ab7e016d6c814819"
        end
      end
    end

    # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0
    resource "cargo-bootstrap" do
      on_macos do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/cargo-1.97.1-aarch64-apple-darwin.tar.xz", using: :nounzip
          sha256 "2d84a74e9558192a7de674aca6aa3ab7464bed2df97e0377156ddb7e09a0fd7a"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/cargo-1.97.1-x86_64-apple-darwin.tar.xz", using: :nounzip
          sha256 "1bd1029b579d0563ca851ebd095914871535bfd1978a123eeaa03107e89b0e03"
        end
      end

      on_linux do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/cargo-1.97.1-aarch64-unknown-linux-ohos.tar.xz", using: :nounzip
          sha256 "728357a283c997195c7c01dca06c07358ea24220be30911e62a3e13c16db1ca2"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/cargo-1.97.1-x86_64-unknown-linux-gnu.tar.xz", using: :nounzip
          sha256 "e1be5f5ff7f7f80ca506fb65770b759edbdc6d303781ed71c5de8ec8a8394779"
        end
      end
    end

    # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0
    resource "rust-std-bootstrap" do
      on_macos do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/rust-std-1.97.1-aarch64-apple-darwin.tar.xz", using: :nounzip
          sha256 "a4895f5c6995e83cab8687e46b14324592398049def71ce75ca308c981cf200d"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/rust-std-1.97.1-x86_64-apple-darwin.tar.xz", using: :nounzip
          sha256 "0fa78653023be5bdfeb419edc82e3b1346ccaa23eaa036491cce084101c741dd"
        end
      end

      on_linux do
        on_arm do
          url "https://static.rust-lang.org/dist/2026-07-16/rust-std-1.97.1-aarch64-unknown-linux-ohos.tar.xz", using: :nounzip
          sha256 "c4742e7c72416bbd80863a5ad428742d0e8895d80c87dc0681420f42e6654842"
        end
        on_intel do
          url "https://static.rust-lang.org/dist/2026-07-16/rust-std-1.97.1-x86_64-unknown-linux-gnu.tar.xz", using: :nounzip
          sha256 "1c1e704ae80126b7de34f72ea2825f7fd01736dec20732faed47374b95282fba"
        end
      end
    end
  end

    # ═══════════════════════════════════════════════════════════════════
    # HarmonyOS patches
    #
    # Problem: cargo reaches crates.io/GitHub through the `curl` and `git2`
    # crates, both of which call openssl-probe to export SSL_CERT_FILE /
    # SSL_CERT_DIR. openssl-probe only searches a fixed list of FHS locations,
    # while HarmonyOS keeps its trust store at /etc/ssl/certs/cacert.pem,
    # which is not among the file names it probes: cargo then finds no CA file
    # at all and every HTTPS request fails certificate verification.
    #
    # openssl-probe 0.1.6 is the version cargo builds here (via curl/git2);
    # 0.1.5 is only vendored for rustc-perf, which this formula does not build,
    # so it needs no patch.
    #
    # Cargo is built against the crates vendored in the tarball's `vendor/`
    # tree (`--enable-vendor` + `--frozen`), so the patch also re-records the
    # `.cargo-checksum.json` digest of the file it changes: cargo refuses to
    # build a crate whose recorded digests no longer match its sources.
    # ═══════════════════════════════════════════════════════════════════
    patch do
      file "Patches/rust/0001-openssl-probe-0.1.6-ohos-cacert.patch"
    end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc3a9c90e89f82c52ad3f7f281bf2180bae036c68edc7832c3e52c89e024e8c0"
  end

  depends_on "libgit2"
  depends_on "libssh2"
  depends_on "llvm@22" => :build
  depends_on "lld@22" => :build
  depends_on "openssl@3"
  depends_on "pkgconf"
  depends_on "sqlite"

  uses_from_macos "python" => :build
  uses_from_macos "curl"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Required by Rust, see https://github.com/rust-lang/rust/issues/39870
  preserve_rpath

  link_overwrite "etc/bash_completion.d/cargo"
  # These used to belong in `rustfmt`.
  link_overwrite "bin/cargo-fmt", "bin/git-rustfmt", "bin/rustfmt", "bin/rustfmt-*"

  def llvm
    Formula["llvm@22"]
  end

  def install
    # Ensure that the `openssl` crate picks up the intended library.
    # https://docs.rs/openssl/latest/openssl/#manual
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    ENV["LIBGIT2_NO_VENDOR"] = "1"
    ENV["LIBSQLITE3_SYS_USE_PKG_CONFIG"] = "1"
    ENV["LIBSSH2_SYS_USE_PKG_CONFIG"] = "1"

    # For cargo-bootstrap
    ENV.prepend_path "LD_LIBRARY_PATH", "#{formula_opt_lib("openssl@3")}:#{formula_opt_lib("zlib-ng-compat")}"

    if OS.mac?
      # Requires the CLT to be the active developer directory if Xcode is installed
      ENV["SDKROOT"] = MacOS.sdk_path
      # Fix build failure for compiler_builtins "error: invalid deployment target
      # for -stdlib=libc++ (requires OS X 10.7 or later)"
      ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version

      inreplace "src/tools/cargo/Cargo.toml",
                /^curl\s*=\s*"(.+)"$/,
                'curl = { version = "\\1", features = ["force-system-lib-on-osx"] }'
    end

    if build.stable?
      # Verify resource versions otherwise the build script will download them
      # TODO: `deny_network_access!` can help but will break HEAD build
      bootstrap_version = File.read("src/stage0")[/^compiler_version=v?(\d+(?:\.\d+)+)$/, 1]
      if (resource_version = resource("rustc-bootstrap").version) != bootstrap_version
        odie "Expected #{bootstrap_version} for bootstrap but got #{resource_version}!"
      end
      # Apply same workaround as MacPorts to build on macOS 27 which hits
      # https://github.com/rust-lang/rust/issues/157750 in bootstrap
      # TODO: Remove in 1.99.0
      odie "Remove CARGO_PROFILE_DEV_STRIP workaround!" if bootstrap_version >= "1.98.0"
      ENV["CARGO_PROFILE_DEV_STRIP"] = "none" if OS.mac? && MacOS.version >= :golden_gate

      cache_date = File.basename(File.dirname(resource("rustc-bootstrap").url))
      build_cache_directory = buildpath/"build/cache"/cache_date

      resource("rustc-bootstrap").stage build_cache_directory
      resource("cargo-bootstrap").stage build_cache_directory
      resource("rust-std-bootstrap").stage build_cache_directory
    end

    # rust-analyzer is available in its own formula.
    tools = %w[
      analysis
      cargo
      clippy
      rustdoc
      rustfmt
      rust-analyzer-proc-macro-srv
      rust-demangler
      src
    ]
    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --tools=#{tools.join(",")}
      --llvm-root=#{llvm.opt_prefix}
      --disable-llvm-link-shared
      --enable-profiler
      --enable-vendor
      --disable-cargo-native-static
      --disable-docs
      --disable-lld
      --release-description=#{tap.user}
    ]
    if build.head?
      args << "--disable-rpath"
      args << "--release-channel=nightly"
    else
      args << "--release-channel=stable"
    end

    args << "--build=aarch64-unknown-linux-ohos"
    args << "--host=aarch64-unknown-linux-ohos"
    args << "--target=aarch64-unknown-linux-ohos"

    system "./configure", *args
    system "make"
    system "make", "install"

    bash_completion.install etc/"bash_completion.d/cargo"
    (lib/"rustlib/src/rust").install "library"
    rm([
      bin.glob("*.old"),
      lib/"rustlib/install.log",
      lib/"rustlib/uninstall.sh",
      (lib/"rustlib").glob("manifest-*"),
    ])

    # rust's bootstrap copies LLVM_OBJCOPY out of --llvm-root, which makes this
    # file a verbatim copy of llvm@22's llvm-objcopy and the only artefact in
    # the keg that dynamically links libLLVM, even though llvm@22 is a
    # build-only dependency. Nothing here can invoke it either: rustc only
    # shells out to rust-objcopy when stripping Darwin/Solaris artefacts, and
    # this build ships std for aarch64-unknown-linux-ohos alone. Drop it so the
    # keg carries no llvm@22 runtime reference; use llvm@22's own llvm-objcopy
    # if an objcopy is ever needed. `force: true` keeps this a no-op on the
    # platforms that never ship this file.
    rm lib/"rustlib/aarch64-unknown-linux-ohos/bin/rust-objcopy", force: true
    return unless OS.mac?

    # Replace the renamed llvm-objcopy with a symlink to make sure it can find libLLVM
    arch = Hardware::CPU.arm? ? :aarch64 : Hardware::CPU.arch
    rust_objcopy = lib/"rustlib/#{arch}-apple-darwin/bin/rust-objcopy"
    llvm_objcopy = llvm.opt_bin/"llvm-objcopy"
    rm(rust_objcopy)
    ln_sf llvm_objcopy.relative_path_from(rust_objcopy.dirname), rust_objcopy
  end

  def caveats
    <<~EOS
      Link this toolchain with `rustup` under the name `system` with:
        rustup toolchain link system "$(brew --prefix rust)"

      If you use rustup, avoid PATH conflicts by following instructions in:
        brew info rustup
    EOS
  end

  test do
    require "utils/linkage"

    system bin/"rustdoc", "-h"
    (testpath/"hello.rs").write <<~RUST
      fn main() {
        println!("Hello World!");
      }
    RUST
    system bin/"rustc", "hello.rs"
    assert_equal "Hello World!\n", shell_output("./hello")
    system bin/"cargo", "new", "hello_world", "--bin"
    assert_equal "Hello, world!", cd("hello_world") { shell_output("#{bin}/cargo run").split("\n").last }

    assert_match <<~EOS, shell_output("#{bin}/rustfmt --check hello.rs", 1)
       fn main() {
      -  println!("Hello World!");
      +    println!("Hello World!");
       }
    EOS

    # We only check the tools' linkage here. No need to check rustc.
    expected_linkage = {
      bin/"cargo" => [
        formula_opt_lib("libgit2")/shared_library("libgit2"),
        formula_opt_lib("libssh2")/shared_library("libssh2"),
        formula_opt_lib("openssl@3")/shared_library("libssl"),
      ],
    }
    expected_linkage[bin/"cargo"] << if OS.mac?
      formula_opt_lib("openssl@3")/shared_library("libcrypto")
    else
      formula_opt_lib("curl")/shared_library("libcurl")
    end
    missing_linkage = []
    expected_linkage.each do |binary, dylibs|
      dylibs.each do |dylib|
        next if Utils.binary_linked_to_library?(binary, dylib)

        missing_linkage << "#{binary} => #{dylib}"
      end
    end
    assert missing_linkage.empty?, "Missing linkage: #{missing_linkage.join(", ")}"
  end
end
