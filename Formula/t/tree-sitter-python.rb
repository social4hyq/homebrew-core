class TreeSitterPython < Formula
  desc "Python grammar for tree-sitter"
  homepage "https://github.com/tree-sitter/tree-sitter-python"
  url "https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.25.0/tree-sitter-python.tar.gz"
  sha256 "7bce887eb2f33e94bf74a69645cf5138d4096720e54fd3269a6124c06b93c584"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d33c4b47408eda5ff73b1be7dd0f7b7e02148a38896b673c8cbac52b6dde7aea"
  end

  depends_on "tree-sitter" => :test

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <string.h>
      #include <stdio.h>
      #include <tree_sitter/api.h>

      const TSLanguage *tree_sitter_python(void);

      int main() {
        TSParser *parser = ts_parser_new();
        ts_parser_set_language(parser, tree_sitter_python());

        const char *source_code = "42";
        TSTree *tree = ts_parser_parse_string(
          parser,
          NULL,
          source_code,
          strlen(source_code)
        );

        TSNode root_node = ts_tree_root_node(tree);
        char *string = ts_node_string(root_node);
        printf("%s\\n", string);

        free(string);
        ts_tree_delete(tree);
        ts_parser_delete(parser);
        return 0;
      }
    C
    system ENV.cc, "test.c",
                   "-I#{include}", "-I#{Formula["tree-sitter"].opt_include}",
                   "-L#{lib}", "-L#{Formula["tree-sitter"].opt_lib}",
                   "-ltree-sitter", "-ltree-sitter-python",
                   "-o", "test"
    expected = "(module (expression_statement (integer)))"
    assert_equal expected, shell_output(testpath/"test").strip
  end
end
