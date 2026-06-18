class Gascity < Formula
  desc "Orchestration-builder SDK for multi-agent coding workflows"
  homepage "https://github.com/gastownhall/gascity"
  url "https://github.com/gastownhall/gascity/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "e8cb716c3c37a2a92a0ba3872e57dd101a603a3af7ccc20ad3d925f39ce35c8e"
  license "MIT"
  head "https://github.com/gastownhall/gascity.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e5cbaa285f46e8ea303b199dd4b33825def2e584d10697415c3be3f6a7551da1"
  end

  depends_on "go" => :build
  depends_on "beads"
  depends_on "dolt"
  depends_on "jq"
  depends_on "tmux"

  on_macos do
    depends_on "flock"
  end

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"gc"), "./cmd/gc"
  end

  test do
    (testpath/"city-template.toml").write <<~TOML
      [workspace]
      name = "brew-test"

      [beads]
      provider = "file"
    TOML

    ENV["GC_HOME"] = testpath/".gc-home"
    city = testpath/"brew-city"

    output = shell_output("#{bin}/gc init --skip-provider-readiness --file city-template.toml #{city} 2>&1", 1)
    assert_match "Initialized city \"brew-city\"", output
    assert_path_exists city/"city.toml"
    assert_path_exists city/"pack.toml"
    assert_path_exists city/".gc/beads.json"
    assert_match "name = \"brew-city\"", (city/".gc/site.toml").read
    assert_match "provider = \"file\"", (city/"city.toml").read
  end
end
