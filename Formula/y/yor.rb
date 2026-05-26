class Yor < Formula
  desc "Extensible auto-tagger for your IaC files"
  homepage "https://yor.io/"
  url "https://github.com/bridgecrewio/yor/archive/refs/tags/0.1.200.tar.gz"
  sha256 "157f2fc97aafa815dc5efaf1b398950181678953beff5e7736943b73b618b96a"
  license "Apache-2.0"
  head "https://github.com/bridgecrewio/yor.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a80939068fe49ac63b139f9562b93abf0754367204e58b2fc2c624a61c7bb087"
  end

  depends_on "go" => :build

  def install
    inreplace "src/common/version.go", "Version = \"9.9.9\"", "Version = \"#{version}\""
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yor --version")

    assert_match "yor_trace", shell_output("#{bin}/yor list-tags")
    assert_match "code2cloud", shell_output("#{bin}/yor list-tag-groups")
  end
end
