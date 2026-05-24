class Rhit < Formula
  desc "Nginx log explorer"
  homepage "https://dystroy.org/rhit/"
  url "https://github.com/Canop/rhit/archive/refs/tags/v2.0.4.tar.gz"
  sha256 "3fe31159d6c32c90ec210e13285ae2e82a2b2cecd677c7bcd55363e90cd6103d"
  license "MIT"
  head "https://github.com/Canop/rhit.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6967bac617747fa6f5631ee4797ccd56217ce7a14adef7268d0793558d79c85d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    resource "homebrew-testdata" do
      url "https://raw.githubusercontent.com/Canop/rhit/c78d63b/test-data/access.log"
      sha256 "e9ec07d6c7267ec326aa3f28a02a8140215c2c769ac2fe51b6294152644165eb"
    end

    require "pty"
    require "io/console"

    resource("homebrew-testdata").stage do
      output = ""
      PTY.spawn("#{bin}/rhit --silent-load --length 0 --color no access.log") do |r, _w, _pid|
        r.winsize = [80, 130]
        begin
          r.each_line { |line| output += line.gsub(/\r?\n/, "\n") }
        rescue Errno::EIO
          # GNU/Linux raises EIO when read is done on closed pty
        end
      end

      assert_match <<~EOS, output
        33,468 hits and 405M from 2021/01/22 to 2021/01/22
        ┌──────────┬──────┬─────┬────────────────────┐
        │   date   │ hits │bytes│0                33K│
        ├──────────┼──────┼─────┼────────────────────┤
        │2021/01/22│33,468│ 405M│████████████████████│
        └──────────┴──────┴─────┴────────────────────┘
      EOS
      assert_match <<~EOS, output
        HTTP status codes:
        ┌─────┬─────┬────┬────┐
        │ 2xx │ 3xx │4xx │5xx │
        ├─────┼─────┼────┼────┤
        │79.1%│14.9%│1.2%│4.8%│
        └─────┴─────┴────┴────┘
      EOS
    end
  end
end
