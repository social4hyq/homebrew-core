class Autorestic < Formula
  desc "High level CLI utility for restic"
  homepage "https://autorestic.vercel.app/"
  url "https://github.com/cupcakearmy/autorestic/archive/refs/tags/v1.8.3.tar.gz"
  sha256 "2f9ccdb83621530ebda4d22373554af45eeb550d32924a82249dbc66cb867726"
  license "Apache-2.0"
  head "https://github.com/cupcakearmy/autorestic.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72e29005cb52086fcb4f9c4f9e79677a5adc142dcae52f6a83c0efa69e9c3847"
  end

  depends_on "go" => :build
  depends_on "restic"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"autorestic", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/autorestic --version")

    require "yaml"
    config = {
      "locations" => { "foo" => { "from" => "repo", "to" => ["bar"] } },
      "backends"  => { "bar" => { "type" => "local", "key" => "secret", "path" => "data" } },
    }
    config["version"] = 2

    (testpath/".autorestic.yml").write config.to_yaml
    (testpath/"repo/test.txt").write("This is a testfile")

    system bin/"autorestic", "check"
    system bin/"autorestic", "backup", "-a"
    system bin/"autorestic", "restore", "-l", "foo", "--to", "restore"
    assert compare_file testpath/"repo/test.txt", testpath/"restore"/testpath/"repo/test.txt"
  end
end
