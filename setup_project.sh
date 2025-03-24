#!/bin/bash

WORKSPACE_DIR="/home/vagrant/workspace" 

# Create folder workspace
echo "create folder workspace and change dir"
mkdir "$WORKSPACE_DIR" && cd "$WORKSPACE_DIR"

# Setup folder and git project
echo "git clone project"
git clone git@github.com:Jean1084/project-devops-v1.git

