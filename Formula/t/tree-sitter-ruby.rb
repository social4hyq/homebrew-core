class TreeSitterRuby < Formula
  desc "Ruby grammar for tree-sitter"
  homepage "https://github.com/tree-sitter/tree-sitter-ruby"
  url "https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.tar.xz"
  sha256 "bf2ac68d0311f5e3b0859ef0748aafce5cfeb20b60c4b70b24707128abc12e00"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f39bc074b9019b5473256fa91ab0f65a2ba1c08fc8412794288f416305f160b3"
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

      const TSLanguage *tree_sitter_ruby(void);

      int main() {
        TSParser *parser = ts_parser_new();
        ts_parser_set_language(parser, tree_sitter_ruby());

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
                   "-ltree-sitter", "-ltree-sitter-ruby",
                   "-o", "test"
    expected = "(program (integer))"
    assert_equal expected, shell_output(testpath/"test").strip
  end
end
