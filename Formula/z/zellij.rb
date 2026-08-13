class Zellij < Formula
  desc "Pluggable terminal workspace"
  homepage "https://zellij.dev"
  # Tracks pinned `main` revision (not v0.44.3 tag): that tag pins nix 0.23.1 which
  # predates OHOS support (0.30+); main has the bump. Switch back to a tag at v0.45.0.
  url "https://github.com/zellij-org/zellij.git",
      revision: "5254e4fc1dd784ef872644190dc5e2bcb0981bed", branch: "main"
  version "0.45.0-dev"
  license "MIT"
  revision 2

  livecheck do
    url "https://api.github.com/repos/zellij-org/zellij/commits?sha=main&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zellij-v0.45.0-dev-r5"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "63e82b5603ede905d7b821bb4c1993614a390a619cb4a1b8ba8ef4a9f2e133b2"
  end

  depends_on "cmake" => :build
  depends_on "make" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "ohos-compat-shim"
  depends_on "openssl@3"
  depends_on "zlib-ng-compat"

  def install
    ENV["OPENSSL_DIR"] = formula_opt_prefix("openssl@3")

    # OHOS_NDK_HOME must point to ohos-sdk keg root (not native/): aws-lc-sys's
    # build.rs double-appends "native/" to find ohos.toolchain.cmake. aws-lc-sys
    # only has OHOS support via CMake path; NO_ASM panics under --release.
    ENV["OHOS_NDK_HOME"] = formula_opt_prefix("ohos-sdk")

    # Cargo.lock's curl 0.4.44 → socket2 0.4.9 lacks OHOS support; bump curl to 0.4.50
    # (loose isahc requirement allows it) pulls socket2 0.6.5. `--locked` stays consistent.
    system "cargo", "update", "--package", "curl", "--precise", "0.4.50"

    # OHOS strerror_r link fix — same approach as starship.rb.
    (buildpath/"strerror_shim.rs").write <<~RUST
      #[no_mangle]
      pub extern "C" fn __xpg_strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32 {
          extern "C" { fn strerror_r(errnum: i32, buf: *mut u8, buflen: usize) -> i32; }
          unsafe { strerror_r(errnum, buf, buflen) }
      }
    RUST
    system "rustc", "--edition", "2021", "--crate-type", "staticlib", "--emit", "obj",
           "-O", "strerror_shim.rs", "-o", "strerror_shim.o"
    ENV["RUSTFLAGS"] = "-C link-arg=#{buildpath}/strerror_shim.o"

    # Default features kept: pre-built .wasm plugins ship via include_bytes!;
    # vendored_curl/web_server_capability bundle their own C sources.
    system "cargo", "install", *std_cargo_args

    # ohos-compat-shim fixes an intermittent startup crash in a fresh top-level PTY:
    # close_fds's fast path calls SYS_CLOSE_RANGE without an availability probe, and the
    # OHOS kernel SIGSYS-kills the process.
    mkdir_p libexec/"bin"
    mv bin/"zellij", libexec/"bin/zellij"
    (bin/"zellij").write <<~SH
      #!/bin/sh
      exec "#{formula_opt_bin("ohos-compat-shim")}/ohos-shim" "#{opt_libexec}/bin/zellij" "$@"
    SH
    chmod 0755, bin/"zellij"

    generate_completions_from_executable(libexec/"bin/zellij", "setup", "--generate-completion",
                                         base_name: "zellij")
  end

  def caveats
    <<~CAVEATS
      rustls-native-certs may not find a usable OHOS system CA store;
      only affects TLS-verified outbound (remote plugins, web server HTTPS) —
      not the local terminal multiplexer itself.
    CAVEATS
  end

  test do
    assert_match "keybinds", shell_output("#{bin}/zellij setup --dump-config")
    assert_match "zellij 0.45.0", shell_output("#{bin}/zellij --version")
  end
end
