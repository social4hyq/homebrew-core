class Graphqlviz < Formula
  desc "GraphQL Server schema visualizer"
  homepage "https://github.com/sheerun/graphqlviz"
  url "https://registry.npmjs.org/graphqlviz/-/graphqlviz-4.0.1.tgz"
  sha256 "1ede0553fe61ca6f59876b31a7d86f8f9aa692456255c1acf91c204feb2e1ef3"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e19df88b9e6d9397cd4803a1e0b9eb88b050eeb6aefb04712f424035bca50922"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    test_file = testpath/"test.graphql"
    test_file.write <<~EOS
      type Query {
        hello: String
      }
    EOS

    output = pipe_output(bin/"graphqlviz", test_file.read)
    assert_match "digraph erd", output
    assert_match version.to_s, shell_output("#{bin}/graphqlviz --version")
  end
end
