class Cfssl < Formula
  desc "CloudFlare's PKI toolkit"
  homepage "https://cfssl.org/"
  url "https://github.com/cloudflare/cfssl/archive/refs/tags/v1.6.5.tar.gz"
  sha256 "b682452402f403b6ee668bb042bd9b753fe48df84fa7a18a1c32606ffd4918af"
  license "BSD-2-Clause"
  head "https://github.com/cloudflare/cfssl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "63b22c729d7b1efc64ad060f0ecac6f10a5a1dc15891d07a319375678cd0feb0"
  end

  depends_on "go" => :build
  depends_on "libtool"

  def install
    ldflags = "-s -w -X github.com/cloudflare/cfssl/cli/version.version=#{version}"

    (buildpath/"cmd").each_child(false) do |cmd|
      system "go", "build", *std_go_args(ldflags:, output: bin/cmd), "./cmd/#{cmd}"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cfssl version")
    assert_match version.to_s, shell_output("#{bin}/cfssljson --version")

    (testpath/"request.json").write <<~JSON
      {
        "CN" : "Your Certificate Authority",
        "hosts" : [],
        "key" : {
          "algo" : "rsa",
          "size" : 4096
        },
        "names" : [
          {
            "C" : "US",
            "ST" : "Your State",
            "L" : "Your City",
            "O" : "Your Organization",
            "OU" : "Your Certificate Authority"
          }
        ]
      }
    JSON
    response_json = shell_output("#{bin}/cfssl genkey -initca request.json")
    response = JSON.parse(response_json)
    assert_match(/^-----BEGIN CERTIFICATE-----.*/, response["cert"])
    assert_match(/.*-----END CERTIFICATE-----$/, response["cert"])
    assert_match(/^-----BEGIN RSA PRIVATE KEY-----.*/, response["key"])
    assert_match(/.*-----END RSA PRIVATE KEY-----$/, response["key"])
  end
end
