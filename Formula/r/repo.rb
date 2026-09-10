class Repo < Formula
  include Language::Python::Shebang

  desc "Repository tool for Android development"
  homepage "https://source.android.com/source/developing.html"
  url "https://gerrit.googlesource.com/git-repo.git",
      tag:      "v2.67",
      revision: "d27d6829a84f488b7253ea693dcc429076c33914"
  license "Apache-2.0"
  revision 1
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f40a74d156f7740478954a8499e9c4445325c9d040225413d00465ac6138645c"
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
