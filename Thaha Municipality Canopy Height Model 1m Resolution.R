# ------------------------------------------ #
#  Forest Canopy Height Mapping - Thaha Municipality
#  Author: B Shorea robusta | www.bishalrayamajhi.com.np
# ------------------------------------------ #

# Set working directory
setwd("D:/R Programming/ThahaCanopyHeight3D/1m")

# ------------------------------------------ #
#         Load & Manage Packages             #
# ------------------------------------------ #

# Install and load pacman for package management
if (!require("pacman")) install.packages("pacman")

# Load all required packages using pacman
pacman::p_load(
  sf,         # Spatial data (shapefiles)
  httr,       # File downloads
  forestdata, # Canopy height model
  ggplot2,    # Data visualization
  raster,     # Raster handling
  rayshader,  # 3D plotting
  magick      # Image annotation
)

# ------------------------------------------ #
#        Download & Extract Shapefile        #
# ------------------------------------------ #

# URL to ZIP containing Nepal local unit shapefiles
zip_url <- "https://admin.opendatanepal.com/dataset/c65ff3d9-f8ce-484a-841c-362d82d3a8f0/resource/a1f8ce1e-b2c6-4123-8dc3-13415be95ddc/download/tmpeb5geft7.zip"

# Define local file path
zip_path <- "local_unit.zip"

# Download the ZIP file
download.file(zip_url, destfile = zip_path, mode = "wb")
cat("Downloaded ZIP file.\n")

# List contents of ZIP file
zip_contents <- unzip(zip_path, list = TRUE)
print(zip_contents)

# Extract files to directory
unzip_dir <- "local_unit"
unzip(zip_path, exdir = unzip_dir)
cat("Extracted ZIP files.\n")

# ------------------------------------------ #
#        Load and Filter Shapefile           #
# ------------------------------------------ #

# Find .shp files in the extracted directory
shp_files <- list.files(unzip_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)

# Stop if no shapefile found
if(length(shp_files) == 0) {
  stop("No .shp file found in extracted ZIP folder.")
} else {
  cat("Found shapefile(s):\n")
  print(shp_files)
}

# Read the first shapefile
local_units <- st_read(shp_files[1])
cat("Shapefile loaded.\n")
crs(local_units)

# Transform CRS to EPSG:4326 (WGS 84)
local_units <- st_transform(local_units, crs = 4326)
cat("Transformed CRS to EPSG:4326.\n")

# Plot all local units of Nepal
plot(local_units$geometry, main = "Nepal Local Units")

# Check column names to confirm correct filtering field
print(names(local_units))

# Filter for Thaha Municipality
thaha_units <- local_units[local_units$GaPa_NaPa == "Thaha", ]

# Display filtered data
print(thaha_units)

# Plot Thaha Municipality
plot(thaha_units$geometry, main = "Thaha Municipality")
crs(thaha_units)

# # ------------------------------------------ #
# #       Plot Thaha Municipality on OSM       #
# # ------------------------------------------ #
# 
# # Set tmap to view mode (interactive with OSM)
# tmap_mode("view")
# 
# # Plot Thaha with OSM background
# tm_shape(thaha_units) +
#   tm_borders(col = "red", lwd = 2) +
#   tm_fill(alpha = 0.3, col = "green") +
#   tm_basemap("OpenStreetMap") +
#   tm_layout(title = "Thaha Municipality on OSM")

# ------------------------------------------ #
#     Load Canopy Height Model (CHM)         #
# ------------------------------------------ #

# Get canopy height model for Thaha
thahachm <- forestdata::fd_canopy_height(
  thaha_units,
  model = "meta",
  layer = "chm",
  crop = TRUE,
  mask = TRUE,
  merge = TRUE
)

class(thahachm)

r_thahachm <- raster::raster(thahachm)

# ------------------------------------------ #
#         FIX: Project raster to EPSG:4326   #
# ------------------------------------------ #

# 🔧 Ensure raster uses same CRS as Thaha Municipality shapefile
r_thahachm_proj <- raster::projectRaster(r_thahachm, crs = crs(thaha_units))

# ------------------------------------------ #
#         Aggregate Raster for Speed         #
# ------------------------------------------ #

r_thahachm_agg <- raster::aggregate(r_thahachm_proj, fact = 5, fun = mean, na.rm = TRUE)

# Convert aggregated raster to dataframe
chm_df <- as.data.frame(r_thahachm_agg, xy = TRUE)
colnames(chm_df) <- c("x", "y", "height")
chm_df <- na.omit(chm_df)

# Confirm value ranges
summary(chm_df$height)

# ------------------------------------------ #
#     Visualize Canopy Height (2D Map)       #
# ------------------------------------------ #

plot(r_thahachm_agg, main = "Aggregated CHM - Thaha")

min_chm_df <- min(chm_df$height)
max_chm_df <- max(chm_df$height)
cat("Minimum Canopy Height (agg):", min_chm_df, "meters\n")
cat("Maximum Canopy Height (agg):", max_chm_df, "meters\n")

breaks <- c(0, 15, 25, 35, max_chm_df)
cols <- c("white", "#ffd3af", "#fbe06e", "#6daa55", "#205544", "#008000")
texture <- colorRampPalette(cols, bias = 2)(6)

# Plot with ggplot2
p <- ggplot(chm_df) + 
  geom_tile(aes(x = x, y = y, fill = height)) +
  geom_sf(data = thaha_units, fill = "transparent", color = "black", size = 1) +
  scale_fill_gradientn(
    name = "height (m)",
    colors = texture,
    breaks = rev(round(breaks, 0))
  ) +
  guides(
    fill = guide_legend(
      direction = "vertical",
      keyheight = unit(4, "mm"),
      keywidth = unit(5, "mm"),
      title.position = "top",
      label.position = "right",
      title.hjust = .5,
      label.hjust = .5,
      ncol = 1
    )
  ) +
  theme_minimal() +
  theme(
    axis.line = element_blank(),
    axis.title = element_blank(),
    axis.text = element_blank(),
    legend.position.inside = c(0.9, .3),
    legend.title = element_text(size = 11, color = "grey10"),
    legend.text = element_text(size = 10, color = "grey10"),
    panel.grid = element_line(color = "white"),
    plot.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA),
    panel.border = element_blank(),
    plot.margin = unit(c(0, 1, 0, 1), "lines")
  )
print(p)

ggsave("canopy_height_thaha.png", plot = p, width = 10, height = 8, dpi = 300)

# ------------------------------------------ #
#       3D Visualization with Rayshader      #
# ------------------------------------------ #

w <- 3500
h <- 2400

rayshader::plot_gg(
  ggobj = p,
  width = 4,
  height = 4.5,
  scale = 50,
  solid = FALSE,
  soliddepth = 0,
  shadow = TRUE,
  shadow_intensity = 0.99,
  offset_edges = FALSE,
  sunangle = 315,
  zoom = 0.5,
  phi = 89.9,
  theta = 0,
  multicore = TRUE
)

# ------------------------------------------ #
#     Export High-Quality 3D Image           #
# ------------------------------------------ #

u <- "https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/8k/je_gray_02_8k.hdr"
download.file(url = u, destfile = basename(u), mode = "wb")

rayshader::render_highquality(
  filename = "scale50.png",
  preview = TRUE,
  light = TRUE,
  environment_light = basename(u),
  intensity_env = 0.9,
  rotate_env = 90,
  interactive = FALSE,
  parallel = TRUE,
  width = 3000,
  height = 2400
)

# ------------------------------------------ #
#     Annotate Map Using {magick}            #
# ------------------------------------------ #

# Load rendered image
map_image <- image_read("scale50.png")

# Set annotation styles
font_main    <- "Georgia"
color_text   <- "black"
size_title   <- 100
size_author  <- 45
size_source  <- 40

# Add main title
map_annotated <- image_annotate(
  map_image,
  text = "Forest Canopy Height of Thaha Municipality, Nepal",
  font = font_main,
  color = color_text,
  size = size_title,
  gravity = "north",
  location = "+0+400"
)

# Add author name
map_annotated <- image_annotate(
  map_annotated,
  text = "©2025 B Shorea robusta (https://bishalrayamajhi.com.np)",
  font = font_main,
  color = color_text,
  size = size_author,
  gravity = "south",
  location = "+0+400"
)

# Add data citation
map_annotated <- image_annotate(
  map_annotated,
  text = ("Data Source: https://doi.org/10.1016/j.rse.2023.113888"),
  font = font_main,
  color = color_text,
  size = size_source,
  gravity = "south",
  location = "+0+450"
)

# Resize for A4 output at 300 DPI
map_a4 <- image_resize(map_annotated, geometry = "3000x2400!")

# Save final annotated map
image_write(
  map_a4,
  path = "Thaha Municipality Canopy Height Model.png",
  format = "png"
)
