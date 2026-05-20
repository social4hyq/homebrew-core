class Spatialindex < Formula
  desc "General framework for developing spatial indices"
  homepage "https://libspatialindex.org/en/latest/"
  url "https://github.com/libspatialindex/libspatialindex/releases/download/2.1.0/spatialindex-src-2.1.0.tar.bz2"
  sha256 "c59932395e98896038d59199f2e2453595df6d730ffbe09d69df2a661bcb619b"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f77198722a45bf5ed989eee28a1400229a37af84ff9961ba211cfe979f04d0c2"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # write out a small program which inserts a fixed box into an rtree
    # and verifies that it can query it
    (testpath/"test.cpp").write <<~CPP
      #include <spatialindex/SpatialIndex.h>

      using namespace std;
      using namespace SpatialIndex;

      class MyVisitor : public IVisitor {
      public:
          vector<id_type> matches;

          void visitNode(const INode& n) {}
          void visitData(const IData& d) {
              matches.push_back(d.getIdentifier());
          }
          void visitData(std::vector<const IData*>& v) {}
      };

      int main(int argc, char** argv) {
          IStorageManager* memory = StorageManager::createNewMemoryStorageManager();
          id_type indexIdentifier;
          RTree::RTreeVariant variant = RTree::RV_RSTAR;
          ISpatialIndex* tree = RTree::createNewRTree(
              *memory, 0.5, 100, 10, 2,
              variant, indexIdentifier
          );
          /* insert a box from (0, 5) to (0, 10) */
          double plow[2] = { 0.0, 0.0 };
          double phigh[2] = { 5.0, 10.0 };
          Region r = Region(plow, phigh, 2);

          std::string data = "a value";

          id_type id = 1;

          tree->insertData(data.size() + 1, reinterpret_cast<const unsigned char*>(data.c_str()), r, id);

          /* ensure that (2, 2) is in that box */
          double qplow[2] = { 2.0, 2.0 };
          double qphigh[2] = { 2.0, 2.0 };
          Region qr = Region(qplow, qphigh, 2);
          MyVisitor q_vis;

          tree->intersectsWithQuery(qr, q_vis);

          return (q_vis.matches.size() == 1) ? 0 : 1;
      }
    CPP
    system ENV.cxx, "-std=c++11", "test.cpp", "-L#{lib}", "-lspatialindex", "-o", "test"
    system "./test"
  end
end
