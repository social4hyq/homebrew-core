class Tygo < Formula
  desc "Generate Typescript types from Golang source code"
  homepage "https://github.com/gzuidhof/tygo"
  url "https://github.com/gzuidhof/tygo.git",
      tag:      "v0.2.21",
      revision: "0b55b7f6509c82f14206cc704eb4a230ece9efe4"
  license "MIT"
  head "https://github.com/gzuidhof/tygo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36c14844f8757544ceb25ca8553914f57ab577a2d222b6e705acbf4073f5b8f3"
  end

  depends_on "go" => [:build, :test]

  def install
    ldflags = %W[
      -s -w
      -X github.com/gzuidhof/tygo/cmd.version=#{version}
      -X github.com/gzuidhof/tygo/cmd.commit=#{Utils.git_head}
      -X github.com/gzuidhof/tygo/cmd.commitDate=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"tygo", shell_parameter_format: :cobra)
    pkgshare.install "examples"
  end

  test do
    (testpath/"tygo.yml").write <<~YAML
      packages:
        - path: "simple"
          type_mappings:
            time.Time: "string /* RFC3339 */"
            null.String: "null | string"
            null.Bool: "null | boolean"
            uuid.UUID: "string /* uuid */"
            uuid.NullUUID: "null | string /* uuid */"
    YAML

    system "go", "mod", "init", "simple"
    cp pkgshare/"examples/simple/simple.go", testpath
    system bin/"tygo", "--config", testpath/"tygo.yml", "generate"
    assert_match "source: simple.go", (testpath/"index.ts").read

    assert_match version.to_s, shell_output("#{bin}/tygo --version")
  end
end
