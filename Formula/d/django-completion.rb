class DjangoCompletion < Formula
  desc "Bash completion for Django"
  homepage "https://www.djangoproject.com/"
  url "https://github.com/django/django/archive/refs/tags/6.0.8.tar.gz"
  sha256 "ae848fbfefee9fe2ea453a5f51c98426d54d615144c797b429b59665166ca34e"
  license "BSD-3-Clause"
  head "https://github.com/django/django.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d46e442e1b40d4ac6f98e78b3a7cd828a2f27d342496a940a03c980a7b82e2d"
  end

  def install
    bash_completion.install "extras/django_bash_completion" => "django"
  end

  test do
    assert_match "-F _django_completion",
      shell_output("bash -c 'source #{bash_completion}/django && complete -p django-admin'")
  end
end
