class Himalaya < Formula
  desc "CLI email client written in Rust"
  homepage "https://github.com/pimalaya/himalaya"
  url "https://github.com/pimalaya/himalaya/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "3d04afdf6f753219c2203feb8094a2ec82c77bab7f9acbe1811773e2a4562877"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72dc351f0169fe4576f588ef6a685978e1b24039f4a71ce59c6e03dc5aaf7f3c"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args

    system bin/"himalaya", "man", buildpath
    man1.install Dir["*.1"]
    generate_completions_from_executable(bin/"himalaya", "completion")
  end

  test do
    # See https://github.com/pimalaya/himalaya#configuration
    (testpath/".config/himalaya/config.toml").write <<~TOML
      [accounts.gmail]
      default = true
      email = "example@gmail.com"

      folder.alias.inbox = "INBOX"
      folder.alias.sent = "[Gmail]/Sent Mail"
      folder.alias.drafts = "[Gmail]/Drafts"
      folder.alias.trash = "[Gmail]/Trash"

      backend.type = "imap"
      backend.host = "imap.gmail.com"
      backend.port = 993
      backend.login = "example@gmail.com"
      backend.auth.type = "password"
      backend.auth.raw = "*****"

      message.send.backend.type = "smtp"
      message.send.backend.host = "smtp.gmail.com"
      message.send.backend.port = 465
      message.send.backend.login = "example@gmail.com"
      message.send.backend.auth.type = "password"
      message.send.backend.auth.cmd = "*****"
    TOML

    assert_match "cannot authenticate to IMAP server", shell_output("#{bin}/himalaya 2>&1", 1)
  end
end
