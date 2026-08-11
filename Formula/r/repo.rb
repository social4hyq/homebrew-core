class Repo < Formula
  include Language::Python::Shebang

  desc "Repository tool for Android development"
  homepage "https://source.android.com/source/developing.html"
  url "https://gerrit.googlesource.com/git-repo.git",
      tag:      "v2.66.1",
      revision: "b85886fa9f5b4e2189cc5b2f40bd0a80459d4c77"
  license "Apache-2.0"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "656f3c9f7c163c5c3fa272c722341794fb7682921de3eac05cc8aec10550915c"
  end

  uses_from_macos "python"

  def install
    bin.install "repo"
    doc.install (buildpath/"docs").children

    rewrite_shebang detected_python_shebang(use_python_from_path: true), bin/"repo"
  end

  test do
    assert_match "usage:", shell_output("#{bin}/repo help 2>&1")
  end
end
