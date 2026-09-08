class Rustypaste < Formula
  desc "Minimal file upload/pastebin service"
  homepage "https://blog.orhun.dev/blazingly-fast-file-sharing"
  url "https://github.com/orhun/rustypaste/archive/refs/tags/v0.18.1.tar.gz"
  sha256 "4b63be093e080d4a39e9ca03b378df96f0ae604e469a9c4d9bb437f9643524f0"
  license "MIT"
  head "https://github.com/orhun/rustypaste.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2c2ec952434a9e82e98914692ccc250269f8a2ad688143734055e7a7964a2c1c"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "config.toml"
  end

  def caveats
    <<~EOS
      An example config is installed to #{opt_pkgshare}/config.toml
    EOS
  end

  test do
    cp pkgshare/"config.toml", testpath/"config.toml"
    port = free_port
    address = "127.0.0.1:#{port}"
    inreplace testpath/"config.toml",
              'address = "127.0.0.1:8000"',
              %Q(address = "#{address}")

    begin
      server = spawn bin/"rustypaste"
      sleep 1

      file = "awesome.txt"
      text = "some text"
      (testpath/file).write text
      url = shell_output("curl -F file=@#{file} http://#{address}").chomp
      assert_equal text, shell_output("curl #{url}")
    ensure
      Process.kill "TERM", server
      Process.wait server
    end
  end
end
