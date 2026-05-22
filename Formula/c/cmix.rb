class Cmix < Formula
  desc "Data compression program with high compression ratio"
  homepage "https://www.byronknoll.com/cmix.html"
  license "GPL-3.0-or-later"
  head "https://github.com/byronknoll/cmix.git", branch: "master"

  stable do
    url "https://github.com/byronknoll/cmix/archive/refs/tags/v21.tar.gz"
    sha256 "c0ff50f24604121bd7ccb843045c0946db1077cfb9ded10fe4c181883e6dbb42"

    # patch makefile, upstream pr ref, https://github.com/byronknoll/cmix/pull/69
    patch do
      url "https://github.com/byronknoll/cmix/commit/702022a974cbf7906bcbaed898f1de95d3cbb32d.patch?full_index=1"
      sha256 "62143fadb5dda1024b0d51c1bb86263eb15d842193e02550a65924b3ac86c28a"
    end

    # Workaround for the error: "This header is only meant to be used on x86 and x64 architecture"
    patch do
      url "https://github.com/byronknoll/cmix/commit/51c8f57570e4c1eb08056f929a96b3101c0156bb.patch?full_index=1"
      sha256 "c199390a27bce681e42ac23c8adfaa7261d4ec11fd76f14f9aab00dc629c2d33"
    end

    # Fix to error: unknown type name '__m128i' on intel architectures
    # PR ref: https://github.com/byronknoll/cmix/pull/74
    patch do
      url "https://github.com/byronknoll/cmix/commit/b5b77acd112985cf8577ec01910c74fb70c98f36.patch?full_index=1"
      sha256 "e9ea39d1d343bd5bc59de497e899d6e124e4d2aa8768e8d0a7fe47ff7a80dc38"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "754cab4578bef046b6b10b160d675943d5e1ee937647ee3e4e4515913258d711"
  end

  def install
    system "make", "CXX=#{ENV.cxx}"
    bin.install "cmix"
  end

  test do
    (testpath/"foo").write "test"
    system bin/"cmix", "-c", "foo", "foo.cmix"
    system bin/"cmix", "-d", "foo.cmix", "foo.unpacked"
    assert_equal "test", shell_output("cat foo.unpacked")
  end
end
