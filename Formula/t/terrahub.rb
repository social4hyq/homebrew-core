class Terrahub < Formula
  desc "Terraform automation and orchestration tool"
  homepage "https://web.archive.org/web/20240302100339/https://docs.terrahub.io/"
  url "https://registry.npmjs.org/terrahub/-/terrahub-0.5.9.tgz"
  sha256 "0288f47ab305550d0f21633a9a487e1de688556229242bf0c86e120d1240e1c4"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "30950a9e6cda48764f370b652caa99fbfaa9a08ef1285dfe90a12e27d6b1e094"
  end

  deprecate! date: "2025-02-13", because: :unmaintained
  disable! date: "2026-02-13", because: :unmaintained

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/".terrahub.yml").write <<~YAML
      project:
        name: terrahub-demo
        code: abcd1234
      vpc_component:
        name: vpc
        root: ./vpc
      subnet_component:
        name: subnet
        root: ./subnet
    YAML
    output = shell_output("#{bin}/terrahub graph")
    assert_match "Project: terrahub-demo", output
  end
end
