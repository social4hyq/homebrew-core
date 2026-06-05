class Rustscan < Formula
  desc "Modern Day Portscanner"
  homepage "https://github.com/bee-san/RustScan"
  url "https://github.com/bee-san/RustScan/archive/refs/tags/2.4.1.tar.gz"
  sha256 "fa99c18a12d4c0939ab69ddb84ef7b85a1ea01d8fc86df227449d89473531765"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fa60732adc29e876113ff0ee9cf9f28076e046ca4f33aa1866d91cd3df61ad92"
  end

  depends_on "rust" => :build
  depends_on "nmap"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    refute_match("panic", shell_output("#{bin}/rustscan --greppable -a 127.0.0.1"))
    refute_match("panic", shell_output("#{bin}/rustscan --greppable -a 0.0.0.0"))
  end
end
