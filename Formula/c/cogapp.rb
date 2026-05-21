class Cogapp < Formula
  include Language::Python::Virtualenv

  desc "Small bits of Python computation for static files"
  homepage "https://cog.readthedocs.io/en/latest/"
  url "https://files.pythonhosted.org/packages/64/ea/4ffa8095e0b675e9961cbdcad002c09d35d4ab76ff99d61a014e9e6bcd53/cogapp-3.6.0.tar.gz"
  sha256 "ec2a9170bfa644bf0d91996fdb5576c13d7e5e848bb2378a6f92727b48f92604"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0d3138447e89dd7a94caa3f23a420ae967e4ac4c32161b2c8058584b1c381725"
  end

  depends_on "python@3.14"

  conflicts_with "cocogitto", "cog", because: "both install `cog` binaries"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cog -v")

    (testpath/"test.cpp").write <<~CPP
      /*[[[cog
      import cog
      fnames = ['DoSomething', 'DoAnotherThing', 'DoLastThing']
      for fn in fnames:
          cog.outl("void %s();" % fn)
      ]]]*/
      //[[[end]]]
    CPP

    output = shell_output("#{bin}/cog test.cpp")
    assert_match "void DoSomething();\nvoid DoAnotherThing();\nvoid DoLastThing();", output
  end
end
