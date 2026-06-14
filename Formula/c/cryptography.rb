class Cryptography < Formula
  desc "Cryptographic recipes and primitives for Python"
  homepage "https://cryptography.io/en/latest/"
  url "https://files.pythonhosted.org/packages/1f/99/d1c90d6041656cc6ee229dc99cd67fd0cd5aec3c5f7d72fffc27cc750054/cryptography-49.0.0.tar.gz"
  sha256 "f89660a348f4f78a92366240a61404e337586ef7f5909a2fef59ca88ef505493"
  license any_of: ["Apache-2.0", "BSD-3-Clause"]
  compatibility_version 1
  head "https://github.com/pyca/cryptography.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0c41832cdc18196fd0a41732c7f6b7e2862492d7f65e4e40a7dd3ef0aafd2af"
  end

  depends_on "maturin" => :build
  depends_on "pkgconf" => :build
  depends_on "python-setuptools" => :build
  depends_on "python@3.13" => [:build, :test]
  depends_on "python@3.14" => [:build, :test]
  depends_on "rust" => :build
  depends_on "cffi"
  depends_on "openssl@3"

  pypi_packages exclude_packages: ["cffi", "pycparser"]

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.start_with?("python@") }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    # python-setuptools may only provide site-packages for the highest python version.
    # The cryptography-cffi build.rs imports setuptools.command.build_ext at compile time.
    # Since setuptools is pure Python, we inject the available installation into PYTHONPATH.
    setuptools_lib = Formula["python-setuptools"].opt_lib
    # Use the newest available setuptools site-packages as fallback for all python versions
    setuptools_fallback = Dir["#{setuptools_lib}/python3.*/site-packages"]
                          .select { |d| File.directory?(d) }
                          .max_by { |d| d[/python3\.(\.\d+)/, 1].to_f }

    # TODO: Avoid building multiple times as binaries are already built in limited API mode
    pythons.each do |python3|
      ver = Language::Python.major_minor_version(python3)
      sp = setuptools_lib/"python#{ver}/site-packages"
      ENV["PYTHONPATH"] = sp.directory? ? sp.to_s : setuptools_fallback.to_s
      system python3, "-m", "pip", "install", *std_pip_args, "."
    end
  end

  test do
    (testpath/"test.py").write <<~PYTHON
      from cryptography.fernet import Fernet
      key = Fernet.generate_key()
      f = Fernet(key)
      token = f.encrypt(b"homebrew")
      print(f.decrypt(token))
    PYTHON

    pythons.each do |python3|
      assert_match "b'homebrew'", shell_output("#{python3} test.py")
    end
  end
end
