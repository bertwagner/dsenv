#!/bin/bash

# docker pull pytorch/pytorch:latest
docker run -it --gpus=all --net=host -v ~/:/workspace pytorch/pytorch:latest 