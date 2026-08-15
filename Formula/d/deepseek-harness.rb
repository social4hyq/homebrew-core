class DeepseekHarness < Formula
  desc "Open-source agent harness developed by DeepSeek AI"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.0-rc.6.tgz"
  sha256 "1b8a9a0ad3c7feaece47926e0bd37ca151c7ccfa997953afa5fd01261784eadc"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "bash"
  depends_on "node"
  depends_on "ripgrep"

  def install
    system "npm", "install", *std_npm_args(ignore_scripts: true), "@img/sharp-wasm32"

    Dir.chdir(libexec/"lib/node_modules/@deepseek-ai/dsh") do
      system "npm", "install", "koffi@^3.1.5", "--no-save", "--prefer-online"
      system "npm", "rebuild", "koffi", "node-pty"
    end

    patch_dir = File.expand_path("../../Patches/deepseek-harness", __dir__)
    Dir[File.join(patch_dir, "*.patch")].each do |patch_file|
      system "patch", "-p1", "-d",
             libexec/"lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai",
             "-i", patch_file
    end

    (bin/"dsh").write <<~EOS
      #!/bin/sh
      exec "#{formula_opt_bin("node")/"node"}" --expose-internals "#{libexec/"lib/node_modules/@deepseek-ai/dsh/lib/bin.js"}" "$@"
    EOS
    (bin/"dsh").chmod 0755
  end

  def caveats
    <<~EOS
      Run `dsh` command to use deepseek-harness:

        Web UI:   dsh web
        One-shot: dsh --profile headless "..."
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dsh --version")
  end
end
