class Genoffice < Formula
  desc "Command-line for the GenOffice AI office suite (docx, xlsx, pptx, pdf)"
  homepage "https://github.com/genspark-ai/genoffice"
  url "https://github.com/genspark-ai/genoffice/archive/refs/tags/v0.13.886.tar.gz"
  sha256 "5099683639c438695c119608095349342938263b2191c000e6b989d24f8d3379"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/genoffice-v0.13.886-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9a60103d36220366ff0de236ea4db66d99e53fff65f1d3931d88cdc683e2242"
  end

  depends_on "rust" => :build
  depends_on "node"

  def install
    # root `postinstall` runs install-electron; the CLI does not need it
    system "npm", "ci", "--ignore-scripts"
    # without this the bundle reports the CLI package version (0.10.0)
    ENV["GENOFFICE_APP_VERSION"] = version.to_s
    system "npm", "run", "build", "-w", "@genoffice/cli"
    system "cargo", "install", *std_cargo_args(root: buildpath/"sidecar", path: "apps/sheets/native/xlsx-engine")

    cli = libexec/"cli"
    cli.install "packages/cli/dist/genoffice.cjs"
    cli.install "packages/cli/dist/node_modules"
    (cli/"skills").install "skills/genoffice"
    (libexec/"wasm").install "node_modules/@embedpdf/pdfium/dist/pdfium.wasm"
    (libexec/"native").install "sidecar/bin/xlsx-sidecar"

    node = formula_opt_bin("node")/"node"
    (bin/"genoffice").write <<~SH
      #!/bin/sh
      export GENOFFICE_NODE="#{node}"
      exec "#{node}" "#{opt_libexec}/cli/genoffice.cjs" "$@"
    SH
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/genoffice --version")

    # the formula result is computed by the Rust xlsx sidecar
    (testpath/"cells.json").write '[[1234, 4321, "=A1+B1"]]'
    system bin/"genoffice", "create", "--type", "xlsx", "--from", "cells.json", "--out", "book.xlsx"
    assert_match "xlsx", shell_output("#{bin}/genoffice info book.xlsx")
    assert_match "5555", shell_output("#{bin}/genoffice sheet read book.xlsx --json")

    (testpath/"doc.md").write "# Harmonybrew sample\n\nhello office\n"
    system bin/"genoffice", "create", "--type", "docx", "--from", "doc.md", "--out", "doc.docx"
    assert_match "docx", shell_output("#{bin}/genoffice info doc.docx")
  end
end
