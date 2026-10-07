class LohMihomo < Formula
  desc "Manage a mihomo proxy inside HarmonyOS' Linux subsystem (loh)"
  homepage "https://github.com/social4hyq/loh-mihomo"
  url "https://github.com/social4hyq/loh-mihomo/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "a2f137ab6bfd6b86e4428d9d66d3ea6205ff742d5dc4d93fd6b7619fc62da5cc"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  depends_on "ruby"

  resource "mihomo" do
    url "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.31/mihomo-linux-arm64-v1.19.31.gz"
    sha256 "9e0f11afbf38426b8bd88fdc594678f8161c57eccb4e1b77acb12b493904f1d4"
  end

  resource "geoip.metadb" do
    url "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/426f62e175218c1f1d0c909188fbff1746f88042/geoip.metadb"
    sha256 "ff6b4270d940df1cf9007ae1a7cc30bd1216abbd01e78c7e6045e46bf76cf91f"
  end

  resource "geosite.dat" do
    url "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/426f62e175218c1f1d0c909188fbff1746f88042/geosite.dat"
    sha256 "dac4b8b3b5bce1d8e59f75f5f2cb3f61e336aa5f4ac7ce465f9dee5e5b0e0457"
  end

  resource "geolite2-asn-mmdb" do
    url "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/426f62e175218c1f1d0c909188fbff1746f88042/GeoLite2-ASN.mmdb"
    sha256 "e16e2db7ed72adc4443e16d7e33a25120ca58bd8d0f2e902b49ac6c50c3f4815"
  end

  resource "zashboard" do
    url "https://github.com/Zephyruso/zashboard/releases/download/v3.29.1/dist-no-fonts.zip"
    sha256 "21371cd111b6b3d87774f3ea3ddeacdcb0f6aff8690a16d652daa3ea6e3b0145"
  end

  def install
    libexec.install Dir["bin/*"]
    share = libexec/"share"
    ruby_bin = formula_opt_bin("ruby")
    libexec.children.each do |cmd|
      next if cmd.directory?

      (bin/cmd.basename).write_env_script cmd, { "PATH"             => "#{ruby_bin}:$PATH",
                                                 "LOH_MIHOMO_SHARE" => share.to_s }
    end
    share.mkpath

    # Bundled payload so the runtime scripts never need to download anything.
    resource("mihomo").stage do
      gz = Pathname.glob("*").first
      system "gunzip", "-f", gz if gz.to_s.end_with?(".gz")
      src = Pathname.glob("mihomo-linux-arm64*").first || Pathname.glob("*").first
      share.install src => "mihomo.bin"
    end
    resource("geoip.metadb").stage { share.install "geoip.metadb" }
    resource("geosite.dat").stage { share.install "geosite.dat" }
    resource("geolite2-asn-mmdb").stage { share.install "GeoLite2-ASN.mmdb" }
    resource("zashboard").stage do
      system "unzip", "-q", Pathname.glob("*.zip").first if Pathname.glob("dist").empty?
      src = Pathname.glob("dist").first || Pathname.glob("*").first
      share.install src => "ui"
    end
  end

  def caveats
    <<~EOS
      These tools drive mihomo inside HarmonyOS' Linux subsystem through `loh`.
      mihomo, geo data and the Zashboard panel are bundled, so no runtime download
      is needed. First-time setup still needs a Clash/Mihomo subscription URL:
        mkdir -p ~/.local/share/fusion-mihomo
        echo '<your subscription URL>' > ~/.local/share/fusion-mihomo/subscription.url
        fusion-mihomo-update
        fusion-mihomo-setup
      Afterwards use `fusion-mihomo-ensure` to verify, and `fusion-mihomo-proxy` to switch nodes.
    EOS
  end

  test do
    assert_match "fusion-mihomo", shell_output("#{bin}/fusion-mihomo-proxy --help")
  end
end
