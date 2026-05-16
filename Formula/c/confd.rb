class Confd < Formula
  desc "Manage local application configuration files using templates"
  homepage "https://github.com/kelseyhightower/confd"
  url "https://github.com/kelseyhightower/confd/archive/refs/tags/v0.16.0.tar.gz"
  sha256 "4a6c4d87fab77aa9827370541024a365aa6b4c8c25a3a9cab52f95ba6b9a97ea"
  license "MIT"
  head "https://github.com/kelseyhightower/confd.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b24cef1df884be8fd195be044f4af0175e8f4a8fcf5ea87b5a54f719f9a55344"
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "auto"
    (buildpath/"src/github.com/kelseyhightower/confd").install buildpath.children
    cd "src/github.com/kelseyhightower/confd" do
      system "go", "install", "github.com/kelseyhightower/confd"
      bin.install buildpath/"bin/confd"
    end
  end

  test do
    templatefile = testpath/"templates/test.tmpl"
    templatefile.write <<~EOS
      version = {{getv "/version"}}
    EOS

    conffile = testpath/"conf.d/conf.toml"
    conffile.write <<~TOML
      [template]
      prefix = "/"
      src = "test.tmpl"
      dest = "./test.conf"
      keys = [
          "/version"
      ]
    TOML

    keysfile = testpath/"keys.yaml"
    keysfile.write <<~YAML
      version: v1
    YAML

    system bin/"confd", "-backend", "file", "-file", "keys.yaml", "-onetime", "-confdir=."
    assert_path_exists testpath/"test.conf"
    refute_predicate (testpath/"test.conf").size, :zero?
  end
end
