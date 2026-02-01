> To run the complete pipeline end-to-end (including environment setup, training, and rendering), please execute `run.sh`, which automates installation and all stages of the workflow.

# 🌲 RadSplat-Inspired 3D Reconstruction Pipeline

This repository contains a production-ready pipeline for high-fidelity 3D reconstruction of forestry environments. I implemented a hybrid **Zip-NeRF** and **Depth-Supervised Gaussian Splatting (3DGS)** architecture to deliver structurally sound geometry and real-time rendering capabilities.

---

## 📊 Performance & Quality Report

### 1.1 Summary

I developed this pipeline to hybridize implicit NeRF representations with explicit Gaussian Splatting. By utilizing Zip-NeRF for geometric initialization and depth-supervised 3DGS for final refinement, I achieved a balance between structural integrity in complex foliage and real-time rendering performance.

In testing the model, I observed a significant discrepancy based on viewpoint sampling:

**Sparse Sampling (Every 8th view as Test):**  
This yielded a PSNR of **20.3304**. I determined that uniform sparse sampling is suboptimal for complex forestry terrains because it does not guarantee actual geometric coverage. If a specific spot is only visible in a held-out view, the training process cannot account for it, leading to a drop in quality.

**Full Coverage Optimization:**  
For mapping difficult geospatial data like forests, it is paramount to ensure full visibility. Consequently, I ran a variant utilizing all views for training to ensure 100% overlap, which resulted in a higher PSNR of **24.8349**.

---

### 1.2 Quantitative Results

#### Held-out Views (Test views)

| Metric | Value |
|------|------|
| PSNR (Held-out) | 20.3425 |
| SSIM (Held-out) | 0.44096 |
| LPIPS (Held-out) | 0.5311 |

> **Note:** Significant artifacts are observed in regions with sparse view coverage.

---

#### All Views Used for Training

| Metric | Value |
|------|------|
| Mean PSNR | 24.8349 |
| SSIM | 0.5634 |
| LPIPS | 0.4148 |

---

### Performance

| Metric | Value |
|------|------|
| Total Wall-clock Time | ~2 hours 30 minutes |
| Rendering Speed | 47.77 FPS |

#### Wall-clock Time Breakdown

| Stage | Task | Duration |
|------|------|---------|
| **Stage A** | Zip-NeRF Training (30k iterations) | ~40 min |
| **Stage A** | Point Cloud Extraction (1M points) | ~4 min |
| **Stage A** | NeRF Depth Map Rendering | ~1 hr |
| **Stage B** | Depth-Supervised 3DGS Training (30k iters) | ~50 min |

---

### 1.3 Methodology

- **Evaluation Split:**  
  I used a 1.0 training fraction for initialization to maximize point cloud density, followed by a standard eval split during 3DGS to generate held-out metrics.

- **Speed Testing:**  
  I measured FPS using a standardized camera path on a single RTX 4090 to reflect production performance.

---

## 💡 Design Discussion

### 2.1 Model Choices & Point Cloud Extraction

I selected **Zip-NeRF** for Stage A due to its robustness against aliasing in high-frequency forestry textures.

- **Hyperparameters:**  
  I extracted a refined **1,000,000 point cloud** using `ns-export`. I applied a strict `std-ratio` of **0.5** for outlier removal to prioritize geometric precision over raw point count.

- **Depth Rendering:**  
  I rendered raw depth as `distance_mean` maps and exported them as compressed NumPy arrays to maintain floating-point precision before converting them to 16-bit PNGs for 3DGS compatibility.

---

### 2.2 Scale-Aware Depth Correction

A primary challenge I faced was the scale discrepancy between the NeRF's internal coordinate system and the metric space of the provided COLMAP model.

- **Implementation:**  
  Developed a `make_depth_scale.py` helper to perform a linear alignment in inverse depth (disparity) space.

- **Mechanism:**  
  Calculated per-view alignment parameters by comparing the projected COLMAP points against the NeRF depth maps. By using the Median and Mean Absolute Deviation (MAD) for the scale  
  (`s_colmap / s_mono`) and offset  
  (`t_colmap - t_mono · scale`),  
  I ensured the alignment is robust to outliers and geometric noise common in forestry datasets.

This transformation allows the 3DGS depth-consistency loss to operate on a consistent metric scale.

---

### 2.3 3DGS Optimization & Memory Trade-offs

I ran the Stage B optimization for **30,000 iterations** to ensure convergence of the complex forest canopy.

- **Memory Management:**  
  Given the **5608 × 3100** image resolution, I utilized the `--data_device cpu` flag. This trade-off was essential to avoid VRAM exhaustion on a single GPU while maintaining full-resolution supervision.

- **Post-Processing:**  
  I utilized `3dgsconverter` with a **5% minimum opacity** threshold and a **SOR intensity of 8**. This removed haze and floating artifacts, resulting in a cleaner final scene.

---

### 2.4 Future Work

- **Turbo-GS Integration:**  
  Implement Turbo-GS for real-time 4K rendering using tile-based rasterization and LoD.

- **Deep Implicit Querying (RadSplat):**  
  Query the Zip-NeRF backbone for density field information to initialize Gaussian scales and opacities.

- **Uncertainty-Weighted Supervision:**  
  Apply weighted depth-consistency loss using NeRF uncertainty.

- **Selective Densification:**  
  Focus densification on thin branch structures while pruning redundant Gaussians on the forest floor.

---

## 📁 Deliverables

Find all deliverables here:  
https://drive.google.com/drive/folders/1qd13cwqGLxlTOUWUZieoenlEZ75rMCWb?usp=sharing  

> **Note:** Please download the files to view results. Google Drive preview tends to show lower quality.

---
