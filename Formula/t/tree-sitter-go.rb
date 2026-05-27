class TreeSitterGo < Formula
  desc "Go grammar for tree-sitter"
  homepage "https://github.com/tree-sitter/tree-sitter-go"
  url "https://github.com/tree-sitter/tree-sitter-go/releases/download/v0.25.0/tree-sitter-go.tar.gz"
  sha256 "ac412018d59f7cd5bb72fbde557e9ebf9fdfac12c5853f2bb03669f980a953bb"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0155aaf12a56f1f34e013197313c9d0d0b4fbd45471c173abcb7a36a4f9d417"
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

      const TSLanguage *tree_sitter_go(void);

      int main() {
        TSParser *parser = ts_parser_new();
        ts_parser_set_language(parser, tree_sitter_go());

        const char *source_code = "package main\\nimport \\"fmt\\"\\nfunc main() { fmt.Println(\\"Hello, World!\\") }";
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
                   "-ltree-sitter", "-ltree-sitter-go",
                   "-o", "test"
    expected = "(source_file (package_clause (package_identifier)) (import_declaration (import_spec path:" \
               "(interpreted_string_literal (interpreted_string_literal_content)))) (function_declaration name:" \
               "(identifier) parameters: (parameter_list) body: (block (statement_list (expression_statement" \
               "(call_expression function: (selector_expression operand: (identifier) field: (field_identifier))" \
               "arguments: (argument_list (interpreted_string_literal (interpreted_string_literal_content)))))))))"
    assert_equal expected.gsub(/\s+/, "").strip,
                 shell_output(testpath/"test").gsub(/\s+/, "").strip
  end
end
