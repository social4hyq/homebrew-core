class Genoffice < Formula
  desc "Command-line for the GenOffice AI office suite (docx, xlsx, pptx, pdf)"
  homepage "https://github.com/genspark-ai/genoffice"
  url "https://github.com/genspark-ai/genoffice/archive/refs/tags/v0.13.18.tar.gz"
  sha256 "156528d8fa1e6878d6c61d3576d6d6b093eda4abbef223e7fbc4bd4855c9cb08"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/genoffice-v0.13.18-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a15cdb6754af7bf82ebde8b14a66154698967e1610d66608f22210505521fa32"
  end

  depends_on "node" => :build
  depends_on "rust" => :build
  depends_on "node"

  # DRAFT, NOT BUILT. Open items before this can go to a PR:
  # 1. esbuild (install script) and any native npm dep need the
  #    @ohos-npm-ports overrides; copy the approach from multica-app.rb.
  # 2. Confirm `npm ci --ignore-scripts` is enough for `npm run build -w @genoffice/cli`.
  # 3. Verify the packaged layout below against packages/cli/src/resources.ts:
  #    packagedResourcesDir() = <cli dir>/.. and requires wasm/pdfium.wasm.

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
