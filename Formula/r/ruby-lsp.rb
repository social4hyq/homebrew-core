class RubyLsp < Formula
  desc "Opinionated language server for Ruby"
  homepage "https://shopify.github.io/ruby-lsp"
  url "https://github.com/Shopify/ruby-lsp/archive/refs/tags/v0.26.10.tar.gz"
  sha256 "32225c7c1ede0862b4ccbb6fdfff0d79ef16e972d4d7b02e54e8aab6f94351dc"
  license "MIT"
  head "https://github.com/Shopify/ruby-lsp.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a7b5ac42e38c0b73709163968b027be0c409225481f213da2f903835800e7ca3"
  end

  depends_on "ruby"

  def install
    ENV["BUNDLE_VERSION"] = "system" # Avoid installing Bundler into the keg
    ENV["BUNDLE_WITHOUT"] = "development test"
    ENV["GEM_HOME"] = libexec

    system "bundle", "install"
    system "gem", "build", "#{name}.gemspec"
    system "gem", "install", "#{name}-#{version}.gem"

    bin.install libexec/"bin/#{name}"
    bin.env_script_all_files libexec/"bin",
      PATH:     "#{Formula["ruby"].opt_bin}:$PATH",
      GEM_HOME: ENV["GEM_HOME"]
  end

  test do
    json = <<~JSON
      {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
          "rootUri": null,
          "capabilities": {}
        }
      }
    JSON
    input = "Content-Length: #{json.size}\r\n\r\n#{json}"
    output = pipe_output("#{bin}/ruby-lsp 2>&1", input, 0)
    assert_match(/^Content-Length: \d+/i, output)
  end
end
