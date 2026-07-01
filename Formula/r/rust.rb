class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"
  url "https://static.rust-lang.org/dist/rust-1.96.1-aarch64-unknown-linux-ohos.tar.xz"
  sha256 "d45d0d14d5767113df5e98975014209d8a7f7f0988ad68e3413d905b9b94e9e6"
  license any_of: ["Apache-2.0", "MIT"]
  compatibility_version 1
  head "https://github.com/rust-lang/rust.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "121578e9adca0234cb682085dcd1defacc71f818fad59b6d33b9f8c7982f1899"
  end

  depends_on "patchelf" => :build
  depends_on "openssl@3"
  depends_on "zlib-ng-compat"

  link_overwrite "etc/bash_completion.d/cargo"
  link_overwrite "bin/cargo-fmt", "bin/git-rustfmt", "bin/rustfmt", "bin/rustfmt-*"


  def install
    system "./install.sh", "--without=rust-analyzer-preview", "--prefix=#{prefix}"

    system "patchelf", "--add-rpath", Formula["openssl@3"].opt_lib.to_s, "#{bin}/cargo"
    system "patchelf", "--add-rpath", Formula["zlib-ng-compat"].opt_lib.to_s, "#{bin}/cargo"

    rm_r([
      lib/"rustlib/install.log",
      lib/"rustlib/uninstall.sh",
    ])
    rm bin.glob("*.old")

    mv bin/"cargo", bin/"cargo.real"
    (bin/"cargo").write <<~EOS
      #!/bin/sh
      export SSL_CERT_FILE="${SSL_CERT_FILE:-#{HOMEBREW_PREFIX}/etc/openssl@3/cert.pem}"
      exec "#{bin}/cargo.real" "$@"
    EOS

    chmod 0755, bin/"cargo"
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
  end
end
