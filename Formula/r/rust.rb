class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"
  url "https://static.rust-lang.org/dist/rustc-1.95.0-src.tar.gz"
  sha256 "ea9b82a83e46967537c3569ce9d6fa16811c043a96e651376c349e70241ca515"
  license any_of: ["Apache-2.0", "MIT"]
  compatibility_version 1
  head "https://github.com/rust-lang/rust.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec5fcc9ca7a8c3bea871cfe91bb27a18c02f1cdf3bb037c1bba608472d687d89"
  end

  depends_on "patchelf" => :build
  depends_on "openssl@3"
  depends_on "zlib-ng-compat"

  link_overwrite "etc/bash_completion.d/cargo"
  link_overwrite "bin/cargo-fmt", "bin/git-rustfmt", "bin/rustfmt", "bin/rustfmt-*"

  resource "rust-prebuilt-ohos" do
    url "https://static.rust-lang.org/dist/rust-1.95.0-aarch64-unknown-linux-ohos.tar.xz"
    sha256 "42bc29d60fee94e87d841e2dc2e295fa8c9f8907d9b986fd762be3db9904641c"
  end

  def install
    resource("rust-prebuilt-ohos").stage do
      system "./install.sh",
             "--without=rust-analyzer-preview",
             "--prefix=#{prefix}"
    end

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
