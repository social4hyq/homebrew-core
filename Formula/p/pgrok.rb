class Pgrok < Formula
  desc "Poor man's ngrok, multi-tenant HTTP/TCP reverse tunnel solution"
  homepage "https://github.com/pgrok/pgrok"
  url "https://github.com/pgrok/pgrok/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "9d5173d71e223fe77cfbbc9e22dd49a81e2d6452c1d1697b448de81053906213"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "312b6b180bfd068b502251577b8e16dcd7875e3bee2f7eb49fda80b1c82dc994"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.date=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:), "./pgrok/cli"

    etc.install "pgrok.example.yml"
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath

    system bin/"pgrok", "init", "--remote-addr", "example.com:222",
                                "--forward-addr", "http://localhost:3000",
                                "--token", "brewtest"
    assert_match "brewtest", (testpath/"pgrok/pgrok.yml").read

    assert_match version.to_s, shell_output("#{bin}/pgrok --version")
  end
end
