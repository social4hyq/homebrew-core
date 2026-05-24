class Plow < Formula
  desc "High-performance and real-time metrics displaying HTTP benchmarking tool"
  homepage "https://github.com/six-ddc/plow"
  url "https://github.com/six-ddc/plow/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "e1b706c8aa137a09dc4061bd9a01c12ad8bb8e175d28d6180008a2a296349d91"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "daeee1e2628c8cc5a9e163c70d7e077230e5246e69a2b3a6eecccecae85ec827"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")

    generate_completions_from_executable(bin/"plow", shell_parameter_format: "--completion-script-",
                                                     shells:                 [:bash, :zsh])
  end

  test do
    output = "2xx"
    assert_match output.to_s, shell_output("#{bin}/plow -n 1 https://httpbin.org/get")

    assert_match version.to_s, shell_output("#{bin}/plow --version")
  end
end
