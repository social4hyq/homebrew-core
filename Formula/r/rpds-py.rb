class RpdsPy < Formula
  include Language::Python::Virtualenv

  desc "Python bindings to Rust's persistent data structures"
  homepage "https://rpds.readthedocs.io/en/latest/"
  url "https://files.pythonhosted.org/packages/20/af/3f2f423103f1113b36230496629986e0ef7e199d2aa8392452b484b38ced/rpds_py-0.30.0.tar.gz"
  sha256 "dd8ff7cf90014af0c0f787eea34794ebf6415242ee1d6fa91eaba725cc441e84"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dc455d9e7acb844b7668e041e5eef37f1cba17121cc3256b63451e8595430a14"
  end

  depends_on "maturin" => :build
  depends_on "python@3.13" => [:build, :test]
  depends_on "python@3.14" => [:build, :test]
  depends_on "rust" => :build

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.start_with?("python@") }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    pythons.each do |python3|
      system python3, "-m", "pip", "install", *std_pip_args, "."
    end
  end

  test do
    (testpath/"test.py").write <<~EOS
      from rpds import HashTrieMap, HashTrieSet, List

      m = HashTrieMap({"foo": "bar", "baz": "quux"})
      assert m.insert("spam", 37) == HashTrieMap({"foo": "bar", "baz": "quux", "spam": 37})
      assert m.remove("foo") == HashTrieMap({"baz": "quux"})

      s = HashTrieSet({"foo", "bar", "baz", "quux"})
      assert s.insert("spam") == HashTrieSet({"foo", "bar", "baz", "quux", "spam"})
      assert s.remove("foo") == HashTrieSet({"bar", "baz", "quux"})

      L = List([1, 3, 5])
      assert L.push_front(-1) == List([-1, 1, 3, 5])
      assert L.rest == List([3, 5])
    EOS

    pythons.each do |python3|
      system python3, "test.py"
    end
  end
end
