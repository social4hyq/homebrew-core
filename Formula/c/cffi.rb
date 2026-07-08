class Cffi < Formula
  desc "C Foreign Function Interface for Python"
  homepage "https://cffi.readthedocs.io/en/latest/"
  url "https://files.pythonhosted.org/packages/57/5f/ff100cae70ebe9d8df1c01a00e510e45d9adb5c1fdda84791b199141de97/cffi-2.1.0.tar.gz"
  sha256 "efc1cdd798b1aaf39b4610bba7aad28c9bea9b910f25c784ccf9ec1fa719d1f9"
  license "MIT-0"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8cd48b043626700582205412f18b3a9ca100a828e018bf8e2195400287c38a6b"
  end

  depends_on "python@3.13" => [:build, :test]
  depends_on "python@3.14" => [:build, :test]
  depends_on "pycparser"

  uses_from_macos "libffi"

  pypi_packages exclude_packages: "pycparser"

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.start_with?("python@") }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    pythons.each do |python|
      system python, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."
    end
  end

  test do
    assert_empty resources, "This formula should not have any resources!"
    (testpath/"sum.c").write <<~C
      int sum(int a, int b) { return a + b; }
    C

    libsum = testpath/shared_library("libsum")
    system ENV.cc, "-shared", "sum.c", "-o", libsum

    (testpath/"sum.py").write <<~PYTHON
      from cffi import FFI
      ffi = FFI()

      declaration = """
        int sum(int a, int b);
      """

      ffi.cdef(declaration)
      lib = ffi.dlopen("#{libsum}")
      print(lib.sum(1, 2))
    PYTHON

    pythons.each do |python|
      assert_equal 3, shell_output("#{python} sum.py").to_i
    end
  end
end
