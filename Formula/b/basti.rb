class Basti < Formula
  desc "Securely connect to RDS, Elasticache, and other AWS resources in VPCs"
  homepage "https://github.com/basti-app/basti"
  url "https://registry.npmjs.org/basti/-/basti-1.8.0.tgz"
  sha256 "aa64f5afecf7cf43c742034a9ca694fa97a5db0b86be6bb77cfcdc2474cd8011"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4e9fc0e83d237ce803ef3c546cbdb6b6a028ad9d402c994115be6f887f2f98db"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Remove incompatible pre-built binary, session-manager-plugin
    node_modules = libexec/"lib/node_modules/basti/node_modules"
    node_modules.glob("basti-session-manager-binary-*/*").each do |f|
      next if f.arch == Hardware::CPU.arch

      rm f
    end

    generate_completions_from_executable(bin/"basti", "completion",
                                            shells:                 [:bash, :zsh],
                                            shell_parameter_format: :none)
  end

  test do
    output = shell_output("#{bin}/basti cleanup")
    assert_match "No Basti-managed resources found in your account", output

    assert_match version.to_s, shell_output("#{bin}/basti --version")
  end
end
