class Spacer < Formula
  desc "Small command-line utility for adding spacers to command output"
  homepage "https://github.com/samwho/spacer"
  url "https://github.com/samwho/spacer/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "310b08c538c04bae779a1c4786430e974801e8880a4c5256dc0877bc82b61af0"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a913cc55b901e3ad3b1a2e1db4ca5013ff2bb600e84369179d7a5b7a0081eb9b"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/spacer --version").chomp
    date = shell_output("date +'%Y-%m-%d'").chomp
    spacer_in = shell_output(
      "i=0
      while [ $i -le 2 ];
        do echo $i; sleep 1
        i=$(( i + 1 ))
      done | #{bin}/spacer --after 0.5",
    ).chomp
    assert_includes spacer_in, date
  end
end
