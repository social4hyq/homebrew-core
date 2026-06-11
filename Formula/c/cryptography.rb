class Cryptography < Formula
  desc "Cryptographic recipes and primitives for Python"
  homepage "https://cryptography.io/en/latest/"
  url "https://files.pythonhosted.org/packages/12/45/870e7f4bef50e5f53b9f51d4428aee5290eedf58ba443f16b1ebb7ab8e66/cryptography-48.0.1.tar.gz"
  sha256 "266f4ee051abb2f725b74ef8072b521ce1feacf685a3364fa6a6b45548db791a"
  license any_of: ["Apache-2.0", "BSD-3-Clause"]
  compatibility_version 1
  head "https://github.com/pyca/cryptography.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "450b6164eb33da1f5ba3daf3628ff9c3351a65577f48b839eb70d246665f7bd1"
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
