class SnowShotOpencv < Formula
  desc "Open source computer vision library"
  homepage "https://opencv.org/"
  url "https://github.com/opencv/opencv/archive/refs/tags/4.14.0.tar.gz"
  sha256 "ee8fb9b30eb60850431b4656447080e3737b56e45719c92b67f245950609f86e"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(4(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/snow-shot-opencv-v4.14.0-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c460e62eae1395dcef8f093f47d8e39894301d20dcb35cd9fefd580f80cd0671"
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "eigen"
  depends_on "protobuf"

  resource "contrib" do
    url "https://github.com/opencv/opencv_contrib/archive/refs/tags/4.14.0.tar.gz"
    sha256 "4f17abd1bc7f88e19c3380c8de7cbf2d863aced5b5ee8d8934cc7902b67d42c9"

    livecheck do
      formula :parent
    end
  end

  # WeChat QR detector models, used by the wechat_qrcode module
  resource "qr-model-assets" do
    url "https://github.com/WeChatCV/opencv_3rdparty/archive/a8b69ccc738421293254aec5ddb38bd523503252.tar.gz"
    sha256 "7a16ad6ca511c620c2a4cbef2c7cf1ff5c31bd530ac7b43ee2ea8481683df20a"
  end

  def install
    resource("contrib").stage buildpath/"opencv_contrib"

    qr_model_dir = buildpath/"build/downloads/wechat_qrcode"
    mkdir_p qr_model_dir
    resource("qr-model-assets").stage do
      %w[detect.caffemodel detect.prototxt sr.caffemodel sr.prototxt].each do |name|
        cp name, qr_model_dir/name
      end
    end

    # Remove bundled libraries to make sure formula dependencies are used
    rm_r(buildpath/"3rdparty"/"protobuf")

    args = %W[
      -DCMAKE_CXX_STANDARD=17
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DBUILD_JASPER=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_OPENEXR=OFF
      -DBUILD_OPENJPEG=OFF
      -DBUILD_PERF_TESTS=OFF
      -DBUILD_PNG=OFF
      -DBUILD_PROTOBUF=OFF
      -DBUILD_TBB=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_WEBP=OFF
      -DBUILD_ZLIB=OFF
      -DBUILD_opencv_hdf=OFF
      -DBUILD_opencv_java=OFF
      -DBUILD_opencv_python2=OFF
      -DBUILD_opencv_python3=OFF
      -DBUILD_LIST=core,imgproc,objdetect,dnn,fs,wechat_qrcode
      -DOPENCV_ENABLE_NONFREE=ON
      -DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules
      -DOPENCV_GENERATE_PKGCONFIG=ON
      -DPROTOBUF_UPDATE_FILES=ON
      -DWITH_EIGEN=ON
      -DWITH_FFMPEG=OFF
      -DWITH_GPHOTO2=OFF
      -DWITH_GSTREAMER=OFF
      -DWITH_GTK=OFF
      -DWITH_JASPER=OFF
      -DWITH_OPENCL=OFF
      -DWITH_OPENEXR=OFF
      -DWITH_OPENGL=OFF
      -DWITH_KLEIDICV=OFF
      -DWITH_OPENVINO=OFF
      -DWITH_QT=OFF
      -DWITH_TBB=OFF
      -DWITH_VTK=OFF
      -DPROTOBUF_LIBRARY=#{formula_opt_lib("protobuf")}/libprotobuf.so
      -DPROTOBUF_INCLUDE_DIR=#{formula_opt_include("protobuf")}
      -DPROTOBUF_PROTOC_EXECUTABLE=#{formula_opt_bin("protobuf")}/protoc
    ]

    system "cmake", "-S", ".", "-B", "build_shared", *args, *std_cmake_args
    inreplace "build_shared/modules/core/version_string.inc", "#{Superenv.shims_path}/", ""
    system "cmake", "--build", "build_shared"
    system "cmake", "--install", "build_shared"

    # Prevent dependents from using fragile Cellar paths
    inreplace lib/"pkgconfig/opencv4.pc", prefix, opt_prefix
  end

  test do
    (testpath/"runtime.cpp").write <<~CPP
      #include <opencv2/core.hpp>
      #include <opencv2/imgproc.hpp>
      #include <opencv2/wechat_qrcode.hpp>

      int main()
      {
          const cv::Mat image(64, 64, CV_8UC1, cv::Scalar(128));
          cv::Mat blurred;
          cv::GaussianBlur(image, blurred, cv::Size(3, 3), 0);
          if (cv::countNonZero(blurred != 128) != 0) {
              return 1;
          }
          cv::wechat_qrcode::WeChatQRCode detector;
          return detector.detectAndDecode(image).empty() ? 0 : 2;
      }
    CPP
    system ENV.cxx, "-std=c++17", "runtime.cpp", "-I#{include}/opencv4", "-L#{lib}",
           "-lopencv_wechat_qrcode", "-lopencv_imgproc", "-lopencv_core", "-o", "runtime"
    system "./runtime"
    version_header = (include/"opencv4/opencv2/core/version.hpp").read
    assert_match "#define CV_VERSION_MAJOR    4", version_header
    assert_match "#define CV_VERSION_MINOR    14", version_header
  end
end
