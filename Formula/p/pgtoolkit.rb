class Pgtoolkit < Formula
  desc "Tools for PostgreSQL maintenance"
  homepage "https://github.com/grayhemp/pgtoolkit"
  url "https://github.com/grayhemp/pgtoolkit/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "d86f34c579a4c921b77f313d4c7efbf4b12695df89e6b68def92ffa0332a7351"
  license "PostgreSQL"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adcf15b710ebc416e9adfcb703d7512ba1aaa6cc1705a8e49cd081bd9c396720"
  end

  def install
    bin.install "fatpack/pgcompact"
    doc.install %w[CHANGES.md LICENSE.md README.md TODO.md]
  end

  test do
    assert_match "pgcompact - PostgreSQL bloat reducing tool", shell_output("#{bin}/pgcompact --help", 1)
  end
end
