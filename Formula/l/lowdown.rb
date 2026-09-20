class Lowdown < Formula
  desc "Simple markdown translator"
  homepage "https://kristaps.bsd.lv/lowdown"
  url "https://kristaps.bsd.lv/lowdown/snapshots/lowdown-3.2.1.tar.gz"
  sha256 "664afc7c00aadbaf16cdcf7dc464e64b529f432eba9dffc950acb0d55d1be90d"
  license "ISC"
  compatibility_version 1
  head "https://github.com/kristapsdz/lowdown.git", branch: "master"

  livecheck do
    url "https://kristaps.bsd.lv/lowdown/snapshots/"
    regex(/href=.*?lowdown[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02aa41fdb2d0b89518ac18d0617bae8b38f7af951f572461085fdaa65aac5ace"
  end

  depends_on "bmake" => :build

  def install
    configure_args = %W[MANDIR=#{man} PREFIX=#{prefix}]
    if OS.mac?
      File.open("configure.local", "a") do |configure_local|
        configure_local.puts "HAVE_SANDBOX_INIT=0"
      end
      configure_args << "LINKER_SONAME=-install_name"
    end

    system "./configure", *configure_args
    system "bmake"
    system "bmake", "install", "install_libs"
  end

  test do
    expected_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title></title>
      </head>
      <body>
      <h1 id="title">Title</h1>
      <p>Hello, World</p>
      </body>
      </html>
    HTML
    markdown = <<~MARKDOWN
      # Title

      Hello, World
    MARKDOWN
    html = pipe_output("#{bin}/lowdown -s", markdown)
    assert_equal expected_html, html
  end
end
