3D Canopy Height Mapping for Thaha Municipality
This repository contains R code to generate a 3D canopy height model (CHM) for Thaha Municipality, Nepal, using the forestdata package. The project downloads shapefiles, processes canopy height data, and creates both 2D and 3D visualizations with annotations.
Table of Contents

Overview
Prerequisites
Installation
Usage
Data Sources
Output
Author
License

Overview
This script performs the following tasks:

Downloads and extracts shapefiles for Nepal's local units.
Filters for Thaha Municipality.
Retrieves canopy height data using the forestdata package.
Processes and aggregates raster data for performance.
Visualizes the canopy height in 2D using ggplot2 and in 3D using rayshader.
Annotates the final map with magick for publication-quality output.

Prerequisites

R (version 4.0 or higher recommended)
RStudio (optional, for easier script execution)
Internet connection for downloading shapefiles and HDR environment maps

Installation

Clone this repository:git clone https://github.com/bshorearobusta2079/3D-CHM-using-Forestdata-Package-in-R.git


Set your working directory in R to the project folder:setwd("path/to/3D-CHM-using-Forestdata-Package-in-R/1m")


Install required R packages using the provided script (requires pacman for package management):if (!require("pacman")) install.packages("pacman")
pacman::p_load(sf, httr, forestdata, ggplot2, raster, rayshader, magick)



Usage

Run the script ThahaCanopyHeight.R in R or RStudio.
Ensure the working directory is set to the 1m folder within the project.
The script will:
Download and extract shapefiles for Nepal's local units.
Filter for Thaha Municipality.
Retrieve and process canopy height data.
Generate a 2D map (canopy_height_thaha.png).
Create a 3D visualization (scale50.png).
Produce an annotated A4-sized map (Thaha Municipality Canopy Height Model.png).



Data Sources

Shapefiles: Nepal local units from Open Data Nepal
Canopy Height Data: forestdata package, sourced from Lang et al., 2023
Environment Map: HDR image from Poly Haven

Output
The script generates the following files:

canopy_height_thaha.png: 2D canopy height map.
scale50.png: 3D visualization of canopy height.
Thaha Municipality Canopy Height Model.png: Annotated A4-sized map for publication.

Author
B Shorea robustaWebsite: bishalrayamajhi.com.np© 2025 B Shorea robusta
License
This project is licensed under the MIT License. See the LICENSE file for details.
