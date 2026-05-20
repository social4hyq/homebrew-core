class Quran < Formula
  desc "Print Qur'an chapters and verses right in the terminal"
  homepage "https://git.hanabi.in/quran-go"
  url "https://git.hanabi.in/repos/quran-go.git",
      tag:      "v1.0.1",
      revision: "c0e271a69a2e817bf75c8ad79a1fc93aa1b868c9"
  license "AGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48458e8475ffd5a1928b198ac59d8ce0ed3b01e2272dd63bd33827192298b96b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "src/main.go"
  end

  test do
    assert_match "Saheeh International", shell_output("#{bin}/quran ls-translations")

    op = shell_output("#{bin}/quran -trans 20 1:1").strip
    assert_equal "In the name of Allāh, the Entirely Merciful, the Especially Merciful.", op
  end
end
