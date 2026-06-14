class Pygit2 < Formula
  desc "Bindings to the libgit2 shared library"
  homepage "https://github.com/libgit2/pygit2"
  url "https://files.pythonhosted.org/packages/a6/44/415aa93422b4bfc21a6448acb7e16280d5f33a9a3fae38a384e37b046ae4/pygit2-1.19.3.tar.gz"
  sha256 "a543e6d4ebb43825564935758dc234e770016fed673b84370d46ae9580558831"
  license "GPL-2.0-only" => { with: "GCC-exception-2.0" }
  compatibility_version 1
  head "https://github.com/libgit2/pygit2.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a918a4b8c211b3ba331962674709b8513c791d048d2512f13181697218e4fcec"
  end

  depends_on "python@3.13" => [:build, :test]
  depends_on "python@3.14" => [:build, :test]
  depends_on "cffi"
  depends_on "libgit2"

  pypi_packages exclude_packages: %w[cffi pycparser]

  def pythons
    deps.map(&:to_formula)
        .select { |f| f.name.start_with?("python@") }
        .map { |f| f.opt_libexec/"bin/python" }
  end

  def install
    pythons.each do |python3|
      system python3, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."
    end
  end

  test do
    assert_empty resources, "This formula should not have any resources!"

    pythons.each do |python3|
      pyversion = Language::Python.major_minor_version(python3).to_s

      (testpath/pyversion/"hello.txt").write "Hello, pygit2."
      mkdir pyversion do
        system python3, "-c", <<~PYTHON
          import pygit2
          repo = pygit2.init_repository('#{testpath/pyversion}', False) # git init

          index = repo.index
          index.add('hello.txt')
          index.write() # git add

          ref = 'HEAD'
          author = pygit2.Signature('BrewTestBot', 'testbot@brew.sh')
          message = 'Initial commit'
          tree = index.write_tree()
          repo.create_commit(ref, author, author, message, tree, []) # git commit
        PYTHON

        system "git", "status"
        assert_match "hello.txt", shell_output("git ls-tree --name-only HEAD")
      end
    end
  end
end
