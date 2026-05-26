class Bartib < Formula
  desc "Simple timetracker for the command-line"
  homepage "https://github.com/nikolassv/bartib"
  url "https://github.com/nikolassv/bartib/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "29fcfb9fc2a64c11023d4be9904e2c70e49ec1f6c9f8ce4c6ee9d73825d2f6f4"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b0d755e98a7d3d4b3b73b8df03075b530def03c698aaf6b9fa478a451824591e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    bartib_file = testpath/"activities.bartib"
    touch bartib_file
    ENV["BARTIB_FILE"] = bartib_file

    system bin/"bartib", "start", "-d", "task BrewTest", "-p", "project"
    sleep 2
    system bin/"bartib", "stop"
    expected =<<~EOS.strip
      \e[1mproject.......... <1m\e[0m
          task BrewTest <1m

      \e[1mTotal............ <1m\e[0m
    EOS
    assert_equal expected, shell_output("#{bin}/bartib report").strip
  end
end
