class Invoice < Formula
  desc "Command-line invoice generator"
  homepage "https://github.com/maaslalani/invoice"
  url "https://github.com/maaslalani/invoice/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "f34f20f6491f42c0e94dbde433a578f0dba98938f2e3186018d3e16d050abdaf"
  license "MIT"
  head "https://github.com/maaslalani/invoice.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e1267670d3aa40631fc91ab5857fba839ef8ee565e9a355a89c85646e5b630b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
    generate_completions_from_executable(bin/"invoice", shell_parameter_format: :cobra)
  end

  test do
    cmd = "#{bin}/invoice generate --from \"Dream, Inc.\" --to \"Imagine, Inc.\" " \
          "--item \"Rubber Duck\" --quantity 2 --rate 25 " \
          "--tax 0.13 --discount 0.15 " \
          "--note \"For debugging purposes.\""
    assert_equal "Generated invoice.pdf", shell_output(cmd).chomp
    assert_path_exists testpath/"invoice.pdf"
  end
end
