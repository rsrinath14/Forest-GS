OAR_JOB_ID=radsplat CUDA_VISIBLE_DEVICES=0 python train.py -s data --optimizer_type sparse_adam -d depths -r 1 --eval --antialiasing --iterations 30000 --data_device cpu;
