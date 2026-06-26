class Stencil < Formula
  desc "Modern living-template engine for evolving repositories"
  homepage "https://stencil.rgst.io"
  url "https://github.com/rgst-io/stencil/archive/refs/tags/v2.18.2.tar.gz"
  sha256 "de2d799a906f6c0b77373780a3dff242762a96da83469e12b1f06064563f7f46"
  license "Apache-2.0"
  head "https://github.com/rgst-io/stencil.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b8b5e0ce8522bb79a8f804496f1cbbdec004b2f22d1394a61cb03df8493a50f"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X go.rgst.io/stencil/v2/internal/version.version=#{version}
      -X go.rgst.io/stencil/v2/internal/version.builtBy=#{tap.user}
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd/stencil"
    generate_completions_from_executable(bin/"stencil", "completion",
                                          shell_parameter_format: "",
                                          shells:                 [:bash, :zsh, :fish, :pwsh])
  end

  test do
    (testpath/"service.yaml").write "name: test"
    system bin/"stencil"
    assert_path_exists testpath/"stencil.lock"
  end
end
