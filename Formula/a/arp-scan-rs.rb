class ArpScanRs < Formula
  desc "ARP scan tool written in Rust for fast local network scans"
  homepage "https://github.com/kongbytes/arp-scan-rs"
  license "AGPL-3.0-or-later"
  head "https://github.com/kongbytes/arp-scan-rs.git", branch: "master"

  stable do
    url "https://github.com/kongbytes/arp-scan-rs/archive/refs/tags/v0.15.1.tar.gz"
    sha256 "6d478b47bdf00c2618e414d87af496892c5027a5a3d4a438ab92c084c36fa5b6"

    # Workaround for https://github.com/kongbytes/arp-scan-rs/issues/9
    patch :DATA
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4586705eed2ed1b26796e212f0ee87bef3c3921c193ba68f5b5264ead4fb70e8"
  end

  depends_on "rust" => :build

  conflicts_with "arp-scan", because: "both install `arp-scan` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/arp-scan --version")
    assert_match "Default network interface", shell_output("#{bin}/arp-scan -l")
  end
end

__END__
diff --git a/Cargo.toml b/Cargo.toml
index c0db14d..9b49b3b 100644
--- a/Cargo.toml
+++ b/Cargo.toml
@@ -21,9 +21,6 @@ ansi_term = "0.12"
 rand = "0.9"
 ctrlc = "3.5"
 
-[target.'cfg(target_os = "linux")'.dependencies]
-caps = "0.5.6"
-
 # Network
 pnet = "0.35"
 pnet_datalink = "0.35"
@@ -35,3 +32,6 @@ csv = "1.4"
 serde = { version = "1.0", features = ["derive"] }
 serde_json = "1.0"
 serde_yaml = "0.9"
+
+[target.'cfg(target_os = "linux")'.dependencies]
+caps = "0.5.6"
