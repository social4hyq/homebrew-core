class Svu < Formula
  desc "Semantic version utility"
  homepage "https://github.com/caarlos0/svu"
  url "https://github.com/caarlos0/svu/archive/refs/tags/v3.4.1.tar.gz"
  sha256 "b40fe73b43926051885045cdf72a3882d3b5e4826577532bd95ef15a9313e418"
  license "MIT"
  head "https://github.com/caarlos0/svu.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "653494dd729d6320be2f92fb0810e94be9fca22359ebf437e8f7e6952c64cf83"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601} -X main.builtBy=#{tap.user} -X main.treeState=clean"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"svu", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/svu --version")
    system bin/"svu", "init"
    assert_match "svu configuration", (testpath/".svu.yml").read
  end
end
