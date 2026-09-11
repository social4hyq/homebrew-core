class Rathole < Formula
  desc "Reverse proxy for NAT traversal"
  homepage "https://github.com/rathole-org/rathole"
  url "https://github.com/rathole-org/rathole/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "c8698dc507c4c2f7e0032be24cac42dd6656ac1c52269875d17957001aa2de41"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3c3712da287f6c2c2c87c535b30c21a36e3b8031b58e9c898e1bb4d082190f5"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  # rust 1.80 build patch, upstream bug report, https://github.com/rathole-org/rathole/issues/380
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/rathole/rust-1.80.patch"
    sha256 "deca6178df16517f752c309f6290678cbddb24cd3839057f746d0817405965f9"
  end

  def install
    # First fetch all dependencies so socket2 sources exist in the cache
    system "cargo", "fetch"

    # Add OHOS support to socket2 crate (dep lacks target_env = "ohos")
    Dir[File.join(ENV["CARGO_HOME"], "registry/src/**/socket2-*/src/sys/unix.rs")].each do |f|
      inreplace f,
        "target_env = \"musl\",\n            " \
        "all(target_env = \"uclibc\", target_pointer_width = \"32\")",
        "target_env = \"musl\",\n            " \
        "target_env = \"ohos\",\n            " \
        "all(target_env = \"uclibc\", target_pointer_width = \"32\")"
    end

    system "cargo", "install", *std_cargo_args
  end

  service do
    run [opt_bin/"rathole", "#{etc}/rathole/rathole.toml"]
    keep_alive true
    log_path var/"log/rathole.log"
    error_log_path var/"log/rathole.log"
  end

  test do
    bind_port = free_port
    service_port = free_port

    (testpath/"rathole.toml").write <<~TOML
      [server]
      bind_addr = "127.0.0.1:#{bind_port}"#{" "}
      default_token = "1234"#{" "}

      [server.services.foo]
      bind_addr = "127.0.0.1:#{service_port}"
    TOML

    # rathole logs its startup lines from two concurrent tasks, so match the whole log, not just the first line.
    log = testpath/"rathole.log"
    fork do
      exec bin/"rathole", "-s", testpath/"rathole.toml", out: log.to_s
    end
    sleep 5

    output = log.read
    assert_match(/Listening at 127.0.0.1:#{bind_port}/i, output)

    assert_match(/Build Version:\s*#{version}/, shell_output("#{bin}/rathole --version"))
  end
end
