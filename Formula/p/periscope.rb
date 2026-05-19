class Periscope < Formula
  desc "Organize and de-duplicate your files without losing data"
  homepage "https://github.com/anishathalye/periscope"
  url "https://github.com/anishathalye/periscope.git",
      tag:      "v1.0.1",
      revision: "a279bfd38e6ff8f4730e52fc670d8e24b98eda7a"
  license "GPL-3.0-only"
  head "https://github.com/anishathalye/periscope.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a686e5780d16e5641d42a2471201fc5e90d46ead093717213a274d31e057dbad"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{Utils.git_head}
    ]
    system "go", "build", *std_go_args(output: bin/"psc", ldflags:), "./cmd/psc"

    generate_completions_from_executable(bin/"psc", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/psc version")

    # setup
    scandir = testpath/"scandir"
    scandir.mkdir
    (scandir/"a").write("dupe")
    (scandir/"b").write("dupe")
    (scandir/"c").write("unique")

    # scan + summary is correct
    shell_output "#{bin}/psc scan #{scandir} 2>/dev/null"
    summary = shell_output("#{bin}/psc summary").strip.split("\n").map { |l| l.strip.split }
    assert_equal [["tracked", "3"], ["unique", "2"], ["duplicate", "1"], ["overhead", "4", "B"]], summary

    # rm allows deleting dupes but not uniques
    shell_output "#{bin}/psc rm #{scandir/"a"}"
    refute_path_exists (scandir/"a")
    # now b is unique
    shell_output "#{bin}/psc rm #{scandir/"b"} 2>/dev/null", 1
    assert_path_exists (scandir/"b")
    shell_output "#{bin}/psc rm #{scandir/"c"} 2>/dev/null", 1
    assert_path_exists (scandir/"c")

    # cleanup
    shell_output("#{bin}/psc finish")
  end
end
