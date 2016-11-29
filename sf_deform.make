SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

vpath %.cpp $(SRC_DIR):$(SRC_DIR)/Tests:$(SRC_DIR)/GPU:$(SRC_DIR)/CPU:$(SRC_DIR)/Utilities:$(SRC_DIR)/DataLoader:$(SRC_DIR)/Tools
vpath %.cu $(SRC_DIR)/GPU\
			$(SRC_DIR)/Utilities


NVCC=/usr/local/cuda/bin/nvcc


# use isystem for eigen as it forces compiler to supress warnings from
# those files. Eigen generates a lot
CFLAGS=-isystem=/usr/include/eigen3 -isystem=/usr/local/include/eigen3 -I=src -I=src/GPU -I=src/Utilities -c -ccbin=/usr/bin/gcc -std=c++11 -g
LDFLAGS=-lpng

SOURCES = BilateralFilter.cpp TSDFVolume.cpp Camera.cpp \
          BlockTSDFLoader.cpp GPURaycaster.cpp \
          Definitions.cpp DepthMapUtilities.cpp FileUtilities.cpp PgmUtilities.cpp \
          PngUtilities.cpp PngWrapper.cpp RenderUtilities.cpp TSDFLoader.cpp \
          CPURaycaster.cpp CPUTSDFVolume.cpp \
          DepthImage.cpp TUMDataLoader.cpp \
          sf_deform.cpp


CUDA_SOURCES = GPUTSDFVolume.cu GPUMarchingCubes.cu TSDF_utilities.cu Raycaster_kernel.cu cuda_utilities.cu

# Make a copy wihtou sub directories
_OBJECTS=$(SOURCES:.cpp=.o)
_CUDA_OBJECTS=$(CUDA_SOURCES:.cu=.o)
OBJECTS = $(patsubst %,$(OBJ_DIR)/%,$(_OBJECTS)) $(patsubst %,$(OBJ_DIR)/%,$(_CUDA_OBJECTS))


EXECUTABLE=bin/sf_deform
Debug: all

all: $(SOURCES) $(CUDA_SOURCES) $(EXECUTABLE)

$(EXECUTABLE) : $(OBJECTS)
	$(NVCC) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)

$(OBJ_DIR)/%.o : %.cpp
	$(NVCC) $(CFLAGS) $< -o $(OBJ_DIR)/$(@F)

$(OBJ_DIR)/%.o : %.cu
	$(NVCC) $(CFLAGS) -lineinfo -G -dc $< -o $(OBJ_DIR)/$(@F)

clean:
	rm $(OBJ_DIR)/*.o $(EXECUTABLE)

run: all
	$(EXECUTABLE)

