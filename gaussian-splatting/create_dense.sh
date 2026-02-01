export PROJECT_PATH="Plot128_Dataset"

colmap patch_match_stereo \
  --workspace_path $PROJECT_PATH \
  --workspace_format COLMAP \
  --PatchMatchStereo.max_image_size 2500 \
  --PatchMatchStereo.geom_consistency true

colmap stereo_fusion \
  --workspace_path $PROJECT_PATH \
  --workspace_format COLMAP \
  --input_type geometric \
  --output_path $PROJECT_PATH/fused.ply

