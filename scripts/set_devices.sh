#!/bin/bash

# Get the current CUDA_VISIBLE_DEVICES value
current_devices="$CUDA_VISIBLE_DEVICES"
num_devices=$(echo "$current_devices" | tr ',' '\n' | wc -l)
new_devices=$(seq -s ',' 0 $((num_devices - 1)))
# Export the new CUDA_VISIBLE_DEVICES
export CUDA_VISIBLE_DEVICES="$new_devices"
echo "Original CUDA_VISIBLE_DEVICES: $current_devices"
echo "Number of devices detected: $num_devices"
echo "New CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
