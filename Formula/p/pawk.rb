class Pawk < Formula
  include Language::Python::Shebang

  desc "Python line processor (like AWK)"
  homepage "https://github.com/alecthomas/pawk"
  url "https://files.pythonhosted.org/packages/6c/90/2165e9fedd33ac172899aa3df6754971d720bf07eef2a0b049db15a7ad69/pawk-0.8.1.tar.gz"
  sha256 "59ec1a4046cf545e1376c8c0a28f5f178a3b88dbc85fb3772aa3ce8c2e088349"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49490344cc8b3a46d1495e57e8c194b6acd862a87a4a679a65d1a2dce2622183"
  end

  uses_from_macos "python"

  def install
    rewrite_shebang detected_python_shebang(use_python_from_path: true), "pawk.py"
    bin.install "pawk.py" => "pawk"
  end

  test do
    (testpath/"elements.txt").write <<~EOS
      # Name Symbol
      Hydrogen  H
      Helium    He
      Lithium   Li
    EOS
    output = shell_output("#{bin}/pawk -B 'd={}' -E 'json.dumps(d)' '!/^#/ d[f[1]] = f[0]' < elements.txt")
    assert_equal '{"H": "Hydrogen", "He": "Helium", "Li": "Lithium"}', output.strip
  end
end
