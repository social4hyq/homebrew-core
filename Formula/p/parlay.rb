class Parlay < Formula
  desc "Enrich SBOMs with data from third party services"
  homepage "https://github.com/snyk/parlay"
  url "https://github.com/snyk/parlay/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "c1f9eaa073b6c958a0722b145fcea9fa3579c9b5552f3359d86f91917441253b"
  license "Apache-2.0"
  head "https://github.com/snyk/parlay.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "12d31305539d079d2627f4618de399c0f98fa19e0e5c7ebeeef937a18be87cf6"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/snyk/parlay/internal/commands.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"parlay", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/parlay --version")

    # test sbom data from https://github.com/snyk/parlay/blob/main/README.md?plain=1#L82
    (testpath/"sbom.spdx.json").write <<~JSON
      {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": "Example SPDX Document",
        "documentNamespace": "https://spdx.org/spdxdocs/example-spdx-document",
        "packages": [
          {
            "name": "concat-map",
            "SPDXID": "SPDXRef-7-concat-map-0.0.1",
            "versionInfo": "0.0.1",
            "downloadLocation": "NOASSERTION",
            "copyrightText": "NOASSERTION",
            "externalRefs": [
              {
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": "pkg:npm/concat-map@0.0.1"
              }
            ]
          }
        ]
      }
    JSON

    # enrich the SBOM with ecosyste.ms data
    enriched_output = shell_output("#{bin}/parlay ecosystems enrich sbom.spdx.json")
    enriched_json = JSON.parse(enriched_output)

    package = enriched_json["packages"].first
    assert_equal "https://github.com/ljharb/concat-map#readme", package["homepage"]
    assert_equal "MIT", package["licenseConcluded"]
    assert_equal "concatenative mapdashery", package["description"]
  end
end
