class Driftwood < Formula
  desc "Private key usage verification"
  homepage "https://trufflesecurity.com/"
  url "https://github.com/trufflesecurity/driftwood/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "655e7f5841a97820adf11b608b41f88cc93953c8c5e1d497bdbd86e5662b2621"
  license "Apache-2.0"
  head "https://github.com/trufflesecurity/driftwood.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5926c99ed5f34866a945eb2d2a7c0b6d09d06da41ac5acbbd3b219f952363ef7"
  end

  deprecate! date: "2025-04-27", because: :repo_archived, replacement_formula: "trufflehog"
  disable! date: "2026-04-27", because: :repo_archived, replacement_formula: "trufflehog"

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    # fake self-signed cert
    (testpath/"fake.pem").write <<~EOS
      -----BEGIN CERTIFICATE-----
      MIID8zCCAtugAwIBAgIUEA5o49g6pqyhfG0NwT8lggIJGt0wDQYJKoZIhvcNAQEL
      BQAwgYgxCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJOWTERMA8GA1UEBwwITmV3IFlv
      cmsxETAPBgNVBAoMCEhvbWVicmV3MRYwFAYDVQQLDA1ob21lYnJldy1jb3JlMREw
      DwYDVQQDDAhicmV3dGVzdDEbMBkGCSqGSIb3DQEJARYMdGVzdEBicmV3LnNoMB4X
      DTIzMDcwMzIyMTk1N1oXDTMzMDYzMDIyMTk1N1owgYgxCzAJBgNVBAYTAlVTMQsw
      CQYDVQQIDAJOWTERMA8GA1UEBwwITmV3IFlvcmsxETAPBgNVBAoMCEhvbWVicmV3
      MRYwFAYDVQQLDA1ob21lYnJldy1jb3JlMREwDwYDVQQDDAhicmV3dGVzdDEbMBkG
      CSqGSIb3DQEJARYMdGVzdEBicmV3LnNoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
      MIIBCgKCAQEAtzNxXwjc+X3gmLqwR85M5m1JXYT4KNv8lSRM81Mp1T4xgLCXRAzH
      edzmcUveau1//nPxQdvJpwz1XY9cnBze77xnew8kcfakKqrqPHFrn87NHm9kUIIc
      OK7YRCCwrBCZh0DKqZ//8eCymWe85Ezl98AuhE+lKxjg+GdmAB6CMWNIm6+zW+ur
      FEpmzcxPzX0mreeoXLbkg1Hvvw84GuuG2QEKXbUX5be+xMhpGm0NYINUBcjvUWa3
      8+1pLJzx346MKQIIdQVdKkBU85kW2huNjrgT9RSpWoLsKBH8d0S5lInCdFcGpiOF
      s3D2gAJdhh6pVq2F75KooTiW7A4sGDMGUwIDAQABo1MwUTAdBgNVHQ4EFgQUfVU0
      LlOMixqYSC+9jtrKcK/GuFQwHwYDVR0jBBgwFoAUfVU0LlOMixqYSC+9jtrKcK/G
      uFQwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAEiDn0ikzXX26
      NT85Zxv4/7+tMaDtOcZl9VgtYUSHl8Aj6ihLZzJXZdHYZis/8Izmfmtv7qiQ+fBV
      Y2RwRMP/ycm6jMdrfZey1cgRdRtp5yPtLdEndixbQ9uAAXRSCW4D628QpTKK8D0O
      cw5BOZ2Vg5ckAjtsFxvzBr1wobOPXTa9FAKPUJaWiD3z4z4Jd2YdY6CGiPIQpaIF
      VWqWT1a4Nq7cNabns/htjNwU09Fo1B6Mf12u5QjsWF3AdJlVF54DJEB4uNVWaQEW
      qHrD+Any5JCDu1qnVepBEoH1EosIXWa6s1UHCB61i3lbZW54Xhj1KVfLsVg4wfmJ
      3zxOo0lNLQ==
      -----END CERTIFICATE-----
    EOS

    output = shell_output("#{bin}/driftwood #{testpath}/fake.pem 2>&1", 1)
    assert_match "Error computing public key: unsupported key type \\\"CERTIFICATE\\\"", output

    assert_match version.to_s, shell_output("#{bin}/driftwood --version")
  end
end
