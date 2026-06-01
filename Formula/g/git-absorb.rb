class GitAbsorb < Formula
  desc "Automatic git commit --fixup"
  homepage "https://github.com/tummychow/git-absorb"
  url "https://github.com/tummychow/git-absorb/archive/refs/tags/0.9.0.tar.gz"
  sha256 "a0f74e6306d7fbd746d2b4a6856621d46a7f82e3e88b6bb8b6fc0480cf811f53"
  license "BSD-3-Clause"
  head "https://github.com/tummychow/git-absorb.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5430cabb2742be310e82e5b185e9aaea993ac9145082eef9efbc75e8582b9cc2"
  end

  depends_on "asciidoctor" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "libgit2"

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"git-absorb", "--gen-completions")
    cd "Documentation" do
      system "asciidoctor", "-b", "manpage", "git-absorb.adoc"
      man1.install "git-absorb.1"
    end
  end

  test do
    (testpath/".gitconfig").write <<~EOS
      [user]
        name = Real Person
        email = notacat@hotmail.cat
    EOS
    system "git", "init"
    (testpath/"test").write "foo"
    system "git", "add", "test"
    system "git", "commit", "--message", "Initial commit"

    (testpath/"test").delete
    (testpath/"test").write "bar"
    system "git", "add", "test"
    system "git", "absorb"

    require "utils/linkage"
    library = Formula["libgit2"].opt_lib/shared_library("libgit2")
    assert Utils.binary_linked_to_library?(bin/"git-absorb", library),
           "No linkage with #{library.basename}! Cargo is likely using a vendored version."
  end
end
