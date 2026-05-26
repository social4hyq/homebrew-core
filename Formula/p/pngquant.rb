class Pngquant < Formula
  desc "PNG image optimizing utility"
  homepage "https://pngquant.org/"
  url "https://static.crates.io/crates/pngquant/pngquant-3.0.3.crate"
  sha256 "68a12bdd8825f9989f4ee9a6ab0b42727dae57728b939ef63453366697a07232"
  license all_of: ["GPL-3.0-or-later", "HPND", "BSD-2-Clause"]
  head "https://github.com/kornelski/pngquant.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "df2725fccbd4a639faa6c30d9475b456476c7842163f621497ecd869a35b48b3"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "libpng"
  depends_on "little-cms2"

  # remove when upstream merge and release https://github.com/kornelski/pngquant/pull/418
  resource "manpage" do
    url "https://raw.githubusercontent.com/kornelski/pngquant/53a332a58f44357b6b41842a54d74aa1e245913d/pngquant.1"
    sha256 "831f485ccb3664436e72c4c8142f15cc35b93854e18c5f01f0d2f3dbc918d374"
  end

  def install
    system "cargo", "install", *std_cargo_args

    man1.install resource("manpage")
  end

  test do
    system bin/"pngquant", test_fixtures("test.png"), "-o", "out.png"
    assert_path_exists testpath/"out.png"
  end
end
