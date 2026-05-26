class Youplot < Formula
  desc "Command-line tool that draw plots on the terminal"
  homepage "https://github.com/red-data-tools/YouPlot/"
  url "https://github.com/red-data-tools/YouPlot/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "2d17a58a5faf684d5df1008d373caed796a88f880dab1d36023bacae97096180"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13c64a3bd894ca42f7574f40a9bb86d8c6b7beb5faeff9f1f826fc1ef4752495"
  end

  depends_on "ruby"

  resource "enumerable-statistics" do
    url "https://rubygems.org/downloads/enumerable-statistics-2.0.9.gem"
    sha256 "9d92f049489b6ad794789814250e8a40e40e5aa6fc742bc7c6192e1ac52cbe3c"
  end

  resource "unicode_plot" do
    url "https://rubygems.org/downloads/unicode_plot-0.0.5.gem"
    sha256 "91ce6237bca67a3b969655accef91024c78ec6aad470fcddeb29b81f7f78f73b"
  end

  resource "csv" do
    url "https://rubygems.org/downloads/csv-3.3.0.gem"
    sha256 "0bbd1defdc31134abefed027a639b3723c2753862150f4c3ee61cab71b20d67d"
  end

  def install
    ENV["GEM_HOME"] = libexec
    resources.each do |r|
      system "gem", "install", r.cached_download, "--ignore-dependencies",
             "--no-document", "--install-dir", libexec
    end
    system "gem", "build", "youplot.gemspec"
    system "gem", "install", "--ignore-dependencies", "youplot-#{version}.gem"
    bin.install libexec/"bin/youplot", libexec/"bin/uplot"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    (testpath/"test.csv").write <<~CSV
      A,20
      B,30
      C,40
      D,50
    CSV
    expected_output = [
      "     ┌          ┐ ",
      "   A ┤■■ 20       ",
      "   B ┤■■■■ 30     ",
      "   C ┤■■■■■ 40    ",
      "   D ┤■■■■■■ 50   ",
      "     └          ┘ ",
      "",
    ].join("\n")
    output_youplot = shell_output("#{bin}/youplot bar -o -w 10 -d, #{testpath}/test.csv")
    assert_equal expected_output, output_youplot
    output_uplot = shell_output("#{bin}/youplot bar -o -w 10 -d, #{testpath}/test.csv")
    assert_equal expected_output, output_uplot
  end
end
