class EcsDeploy < Formula
  include Language::Python::Virtualenv

  desc "CLI tool to simplify Amazon ECS deployments, rollbacks & scaling"
  homepage "https://github.com/fabfuel/ecs-deploy"
  url "https://files.pythonhosted.org/packages/d4/8c/a098b7e3d793b004d917d9a5fc9539eaec60653a1f61761d55a91d1d4f8c/ecs_deploy-1.17.0.tar.gz"
  sha256 "7f8be36edb2321e84c286fc2d9fd9295ff7063d901edffcbac0ce3d891081a9d"
  license "BSD-3-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c68863eb491006a7bd5eddb92bcd819ac218f2fdf303bdf600089b64aa745e5"
  end

  depends_on "certifi"
  depends_on "python@3.14"

  pypi_packages exclude_packages: "certifi"

  resource "boto3" do
    url "https://files.pythonhosted.org/packages/47/e4/139572e2459b7e10cd3409888a7312b8b5054c85ea41b28af417002af1c4/boto3-1.43.73.tar.gz"
    sha256 "6e6c755e5039f204882c01d7936a46abce539b3f5bbb534a23a3f2afbc86f576"
  end

  resource "botocore" do
    url "https://files.pythonhosted.org/packages/e3/ea/c8482ada4f409c91e6f9d640ee15838975f2a7c481dff98419a6d176b81a/botocore-1.43.73.tar.gz"
    sha256 "0fa1e63c24b3531be3e1bc1687a88b3be9e63a430153f24edd93efc162bb1c51"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/e5/3f/143b048436775b0f76ac3eec145c019e8173ccc2885c8f20319b996d5e83/charset_normalizer-3.5.1.tar.gz"
    sha256 "6117b84ea48435e5356dc737f5121485c30920ba43375fa7b434fd753df0eac3"
  end

  resource "click" do
    url "https://files.pythonhosted.org/packages/76/d4/81420972a676e8ffea40450d8c8c92943e7218a78fe9b64359836cc9876b/click-8.4.2.tar.gz"
    sha256 "9a6cea6e60b17ebe0a44c5cc636d94f09bd66142c1cd7d8b4cd731c4917a15f6"
  end

  resource "click-log" do
    url "https://files.pythonhosted.org/packages/22/44/3d73579b547f0790a2723728088c96189c8b52bd2ee3c3de8040efc3c1b8/click-log-0.3.2.tar.gz"
    sha256 "16fd1ca3fc6b16c98cea63acf1ab474ea8e676849dc669d86afafb0ed7003124"
  end

  resource "dictdiffer" do
    url "https://files.pythonhosted.org/packages/0c/31/84b2b2113c2c972431582bffd74f0d04b5efd9126538127b766275580950/dictdiffer-0.10.0.tar.gz"
    sha256 "0b912acf663949d73b820d3ed59362140a188ab742c94efe13c762dbd24cbbd3"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/cd/63/9496c57188a2ee585e0f1db071d75089a11e98aa86eb99d9d7618fc1edce/idna-3.18.tar.gz"
    sha256 "ffb385a7e039654cef1ab9ef32c6fafe283c0c0467bba1d9029738ce4a14a848"
  end

  resource "jmespath" do
    url "https://files.pythonhosted.org/packages/d3/59/322338183ecda247fb5d1763a6cbe46eff7222eaeebafd9fa65d4bf5cb11/jmespath-1.1.0.tar.gz"
    sha256 "472c87d80f36026ae83c6ddd0f1d05d4e510134ed462851fd5f754c8c3cbb88d"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz"
    sha256 "37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/ac/c3/e2a2b89f2d3e2179abd6d00ebd70bff6273f37fb3e0cc209f48b39d00cbf/requests-2.34.2.tar.gz"
    sha256 "f288924cae4e29463698d6d60bc6a4da69c89185ad1e0bcc4104f584e960b9ed"
  end

  resource "s3transfer" do
    url "https://files.pythonhosted.org/packages/76/43/35e4d8aa320bffe8287fe8f65f578fa2d2db0a64212f0e710dce58267854/s3transfer-0.19.2.tar.gz"
    sha256 "ba0309fd86be3c27dbf78cdd813c13c5e1df16e5874b99d2535ebbdfb9892993"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/94/e7/b2c673351809dca68a0e064b6af791aa332cf192da575fd474ed7d6f16a2/six-1.17.0.tar.gz"
    sha256 "ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/53/0c/06f8b233b8fd13b9e5ee11424ef85419ba0d8ba0b3138bf360be2ff56953/urllib3-2.7.0.tar.gz"
    sha256 "231e0ec3b63ceb14667c67be60f2f2c40a518cb38b03af60abc813da26505f4c"
  end

  def install
    virtualenv_install_with_resources

    generate_completions_from_executable(bin/"ecs", shell_parameter_format: :click)
  end

  test do
    ENV["AWS_ACCESS_KEY_ID"] = "test"
    ENV["AWS_SECRET_ACCESS_KEY"] = "test"
    ENV["AWS_DEFAULT_REGION"] = "us-east-1"

    output = shell_output("#{bin}/ecs run TEST_CLUSTER TEST_TASK 2>&1", 1)
    assert_match "Unknown task definition arn: TEST_TASK", output

    assert_match version.to_s, shell_output("#{bin}/ecs --version")
  end
end
