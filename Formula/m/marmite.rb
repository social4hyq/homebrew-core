class Marmite < Formula
  desc "Static Site Generator for Blogs using Markdown"
  homepage "https://rochacbruno.github.io/marmite/"
  url "https://github.com/rochacbruno/marmite/archive/refs/tags/0.4.0.tar.gz"
  sha256 "70b842f5495ea7e233308e97f82ea82db91287b54ad2eace749fa67737c74012"
  license "AGPL-3.0-or-later"
  head "https://github.com/rochacbruno/marmite.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "063b480781ac4349e9d32c8aee74db5f1805b0b8de4b05114051c48bb507424a"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/marmite --version")

    system bin/"marmite", testpath/"site", "--init-site"
    assert_path_exists testpath/"site"
  end
end
