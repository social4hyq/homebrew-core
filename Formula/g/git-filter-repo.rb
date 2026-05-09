class GitFilterRepo < Formula
  include Language::Python::Shebang

  desc "Quickly rewrite git repository history"
  homepage "https://github.com/newren/git-filter-repo"
  url "https://github.com/newren/git-filter-repo/releases/download/v2.47.0/git-filter-repo-2.47.0.tar.xz"
  sha256 "4662cbe5918196a9f1b5b3e1211a32e61cff1812419c21df4f47c5439f09e902"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3dda883ea3ffcbc38ad07fe157be7844f445c7254ca491b36cae04aa42527171"
  end

  uses_from_macos "git"
  uses_from_macos "python"

  def install
    rewrite_shebang detected_python_shebang(use_python_from_path: true), "git-filter-repo"
    bin.install "git-filter-repo"
    man1.install "Documentation/man1/git-filter-repo.1"
  end

  test do
    system bin/"git-filter-repo", "--version"

    system "git", "init"
    system "git", "config", "user.name", "BrewTestBot"
    system "git", "config", "user.email", "BrewTestBot@example.com"

    touch "foo"
    system "git", "add", "foo"
    system "git", "commit", "-m", "foo"
    # Use --force to accept non-fresh clone run:
    # Aborting: Refusing to overwrite repo history since this does not look like a fresh clone.
    # (expected freshly packed repo)
    system bin/"git-filter-repo", "--path-rename=foo:bar", "--force"

    assert_path_exists testpath/"bar"
  end
end
