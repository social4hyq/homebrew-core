class StellarXdr < Formula
  desc "Stellar command-line tool for encoding/decoding XDR for the Stellar network"
  homepage "https://developers.stellar.org"
  url "https://static.crates.io/crates/stellar-xdr/stellar-xdr-27.0.0.crate"
  sha256 "05ff843326969bdf1ef673dcdba94c08f4a3c8f1e58d6e6ef39b1bd4f749179a"
  license "Apache-2.0"
  head "https://github.com/stellar/rs-stellar-xdr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "729e32169c9a1e9b1a771fb44775e22ea48f9f06417475c167cc13ef75520812"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(features: "cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/stellar-xdr version")
    input = "AAAAAAADJH/////9AAAAAA=="
    expected = '{"fee_charged":"205951","result":"tx_too_late","ext":"v0"}'
    assert_match expected, pipe_output("#{bin}/stellar-xdr decode --type TransactionResult", input, 0)
  end
end
