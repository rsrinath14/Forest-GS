#!/bin/bash

DATA_FOLDER=$1

# 1. Create and activate the environment
echo "--- Creating Conda Environment ---"
conda env create -f environment.yaml -y
source $(conda info --base)/etc/profile.d/conda.sh
conda activate take_home_gs

# Fix the C++ Library mismatch
echo "--- Stabilizing C++ Libraries ---"
conda install -c conda-forge libstdcxx-ng --force-reinstall -y
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH

# 2. Install Build Essentials
# Ninja parallelizes the C++/CUDA build, making TCNN install 4x faster
echo "--- Installing Build Tools ---"
pip install ninja

# 3. Install Tiny-CUDA-NN
# Using --no-build-isolation to ensure it finds the torch+cu118 from your yaml
echo "--- Installing Tiny-CUDA-NN ---"
pip install git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch --no-build-isolation

echo "--- Installing submodules ---"
pip install gaussian-splatting/submodules/diff-gaussian-rasterization --no-build-isolation
pip install gaussian-splatting/submodules/simple-knn --no-build-isolation
pip install gaussian-splatting/submodules/fused-ssim --no-build-isolation
pip install git+https://github.com/francescofugazzi/3dgsconverter.git

cd zipnerf-pytorch

# 5. Compile Custom CUDA Extensions
# These are the high-performance kernels for Zip-NeRF
echo "--- Compiling Zip-NeRF Extensions ---"
pip install ./extensions/cuda --no-build-isolation

# 6. Install Zip-NeRF in Editable Mode
echo "--- Finalizing Installation ---"
pip install -e .

echo "--- Setup Complete! ---"
LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH bash zipnerf.sh $DATA_FOLDER

# --- FIX: Path Validation ---
# Ensure the expected output exists before continuing
RENDER_PATH="zipnerf-pytorch/renders/all_outputs/train/raw-depth"
PLY_PATH="zipnerf-pytorch/exports/dense_depth_refined_1M/point_cloud.ply"

cd ..
mkdir -p $DATA_FOLDER/depths
python gaussian-splatting/convert.py --src zipnerf-pytorch/renders/all_outputs/train/raw-depth --dest $DATA_FOLDER/depths
cp -r zipnerf-pytorch/exports/dense_depth_refined_1M/point_cloud.ply $DATA_FOLDER/sparse/points3D.ply


# ln -s $DATA_FOLDER gaussian-splatting/data
cd gaussian-splatting
python utils/make_depth_scale.py --base_dir $DATA_FOLDER --depths_dir $DATA_FOLDER/depths
bash train.sh
3dgsconverter -i output/radsplat/point_cloud/iteration_30000/point_cloud.ply -o output/radsplat/point_cloud/iteration_30000/point_cloud.ply -f 3dgs --min_opacity 5 --sor_intensity 8

# FINAL RENDER (to show the cleaned results for visual inspection)
CUDA_VISIBLE_DEVICES=0 python render.py -m output/radsplat --antialiasing

# UPDATE METRICS (to reflect the improved quality of the clean model)
CUDA_VISIBLE_DEVICES=0 python metrics.py -m output/radsplat

CUDA_VISIBLE_DEVICES=0 python speed_test.py -m output/radsplat;

cd ..

# Preparing deliverables directory
mkdir -p deliverables/zipnerf_rgb
mkdir -p deliverables/zipnerf_depths
mkdir -p deliverables/3dgs_rgb
mkdir -p deliverables/3dgs_depths

cp -r zipnerf-pytorch/renders/all_outputs/train/rgb/* deliverables/zipnerf_rgb/
cp -r $DATA_FOLDER/depths/* deliverables/zipnerf_depths/
cp -r gaussian-splatting/output/radsplat/test/ours_30000/renders/* deliverables/3dgs_rgb/
cp -r gaussian-splatting/output/radsplat/test/ours_30000/depths/* deliverables/3dgs_depths/
cp gaussian-splatting/output/radsplat/input.ply deliverables/zipnerf_pointcloud.ply
cp gaussian-splatting/output/radsplat/point_cloud/iteration_30000/point_cloud.ply deliverables/3dgs_pointcloud.ply

echo "--- Done ---"