import numpy as np
import gzip
from PIL import Image
from pathlib import Path
from argparse import ArgumentParser

parser = ArgumentParser("Convert depth from .npy.gz to 16-bit PNG")
parser.add_argument("--src", default="", type=str, help="Source folder path")
parser.add_argument("--dest", default="", type=str, help="Destination folder path")
args = parser.parse_args()

input_dir = Path(args.src)
output_dir = Path(args.dest)
output_dir.mkdir(exist_ok=True)

for npy_file in input_dir.glob('*.npy.gz'):
    with gzip.open(npy_file, 'rb') as f:
        depth = np.load(f)
    
    depth_normalized = ((depth - depth.min()) / (depth.max() - depth.min()) * 65535).astype(np.uint16)
    
    output_path = output_dir / f"{npy_file.stem.replace('.npy', '')}.png"
    Image.fromarray(depth_normalized.squeeze(), mode='I;16').save(output_path)