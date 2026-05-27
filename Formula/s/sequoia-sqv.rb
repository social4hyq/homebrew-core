class SequoiaSqv < Formula
  desc "Simple OpenPGP signature verification program"
  homepage "https://sequoia-pgp.org/"
  url "https://gitlab.com/sequoia-pgp/sequoia-sqv/-/archive/v1.3.0/sequoia-sqv-v1.3.0.tar.bz2"
  sha256 "cfa9159cbeda4e4d0e3c2778374b24004037bb21d5ea6441f0fb80c68cedfce0"
  license "LGPL-2.0-or-later"
  head "https://gitlab.com/sequoia-pgp/sequoia-sqv.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d47507ee8d7dee390ae747038681a26ca5eb441175842075976b7afa06766f78"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  depends_on "openssl@3"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["ASSET_OUT_DIR"] = buildpath
    system "cargo", "install", "--no-default-features", *std_cargo_args(features: "crypto-openssl")

    man1.install Dir["man-pages/*.1"]
    bash_completion.install "shell-completions/sqv.bash" => "sqv"
    zsh_completion.install "shell-completions/_sqv"
    fish_completion.install "shell-completions/sqv.fish"
  end

  test do
    # https://gitlab.com/sequoia-pgp/sequoia-sqv/-/blob/main/tests/not-before-after.rs
    keyring = "emmelie-dorothea-dina-samantha-awina-ed25519.pgp"
    sigfile = "a-cypherpunks-manifesto.txt.ed25519.sig"
    testfile = "a-cypherpunks-manifesto.txt"
    stable.stage { testpath.install Dir["tests/data/{#{keyring},#{sigfile},#{testfile}}"] }

    output = shell_output("#{bin}/sqv --keyring #{keyring} #{sigfile} #{testfile}")
    assert_equal "8E8C33FA4626337976D97978069C0C348DD82C19\n", output

    output = shell_output("#{bin}/sqv --keyring #{keyring} --not-before 2018-08-15 #{sigfile} #{testfile} 2>&1", 1)
    assert_match "created before the --not-before date", output
  end
end
