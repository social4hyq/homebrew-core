class Rustywind < Formula
  desc "CLI for organizing Tailwind CSS classes"
  homepage "https://github.com/avencera/rustywind"
  url "https://github.com/avencera/rustywind/archive/refs/tags/v0.25.1.tar.gz"
  sha256 "04d1003700490f753dfdec3f2a428d2446f7e5fcbebba013012365f6280f4748"
  license "Apache-2.0"
  head "https://github.com/avencera/rustywind.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "b5fe7dcec93425180860e9fcbc77cf666b2d3fa563e743aa625e16904ded16b5"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "9201254612780d55d30de39013e041f864f5c14464904bcfcafb5e517c601581"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "8674af57e825b7e3796399f05a99f6df396c534f1953f4dbafb78c77ab6374d9"
    sha256 cellar: :any_skip_relocation, sonoma:        "78973848d37e16c0fd9277a0df182b5ec29455300a7c5b110bd55291cdd24e55"
    sha256 cellar: :any,                 arm64_linux:   "41cc84326665f64fe9eb95dcf4933fff12495a2a00fe52196752481abeae03e8"
    sha256 cellar: :any,                 x86_64_linux:  "d7697ea7e079d229c69a7f0dbc272b182134fd2b75fec4685efd133b3d0212a9"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "rustywind-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rustywind --version")

    (testpath/"test.html").write <<~HTML
      <div class="text-center bg-red-500 text-white p-4">
        <p class="text-lg font-bold">Hello, World!</p>
      </div>
    HTML

    system bin/"rustywind", "--write", "test.html"

    expected_content = <<~HTML
      <div class="bg-red-500 p-4 text-center text-white">
        <p class="text-lg font-bold">Hello, World!</p>
      </div>
    HTML

    assert_equal expected_content, (testpath/"test.html").read
  end
end
