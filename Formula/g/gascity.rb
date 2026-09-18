class Gascity < Formula
  desc "Orchestration-builder SDK for multi-agent coding workflows"
  homepage "https://github.com/gastownhall/gascity"
  url "https://github.com/gastownhall/gascity/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "98a4cc61249e7277357b1dd6adf526d64bdf312472f8c5568126c4d586d56d59"
  license "MIT"
  head "https://github.com/gastownhall/gascity.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6c5793e75d58e6b62b58e1fb340d6c58e0695bbaede0c98dc0966b29b0d938e"
  end

  depends_on "go" => :build
  depends_on "beads"
  depends_on "dolt"
  depends_on "icu4c@78"
  depends_on "jq"
  depends_on "tmux"

  on_macos do
    depends_on "flock"
  end

  def install
    # grpc v1.82.1 uses http2.TrailerPrefix which is excluded in
    # golang.org/x/net v0.54.0 on Go ≥1.27 (build constraint). Pin to v0.53.0.
    inreplace "go.mod", /^go\s+\S+$/, "\\0\nreplace golang.org/x/net => golang.org/x/net v0.53.0"
    system "go", "mod", "tidy"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}", output: bin/"gc"), "./cmd/gc"
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
