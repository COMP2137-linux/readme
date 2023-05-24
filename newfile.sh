#!/bin/bash

#created on may24 by amandeep to perform a system update task for the lab

#update the software cache in case it is needed
sudo apt update

#upgrade using new software package versions
sudo apt upgrade -y
