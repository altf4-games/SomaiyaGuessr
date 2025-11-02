const Photo = require("../models/Photo");
const cloudinary = require("../config/cloudinary");

exports.uploadPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No image file provided" });
    }

    const { coordX, coordY, location, difficulty } = req.body;

    if (!coordX || !coordY) {
      return res
        .status(400)
        .json({ error: "Coordinates (coordX, coordY) are required" });
    }

    const result = await new Promise((resolve, reject) => {
      cloudinary.uploader
        .upload_stream(
          {
            folder: "somaiya-guessr",
            transformation: [
              { width: 800, height: 600, crop: "limit" },
              { quality: "auto" },
            ],
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result);
          }
        )
        .end(req.file.buffer);
    });

    const photo = new Photo({
      imageUrl: result.secure_url,
      cloudinaryId: result.public_id,
      coordX: parseFloat(coordX),
      coordY: parseFloat(coordY),
      location: location || "",
      difficulty: difficulty || "medium",
    });

    await photo.save();

    res.json({
      message: "Photo uploaded successfully!",
      photo: {
        id: photo._id,
        imageUrl: photo.imageUrl,
        location: photo.location,
        difficulty: photo.difficulty,
        coordinates: {
          x: photo.coordX,
          y: photo.coordY,
        },
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllPhotos = async (req, res) => {
  try {
    const photos = await Photo.find().sort({ createdAt: -1 });
    res.json({ photos });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deletePhoto = async (req, res) => {
  try {
    const { id } = req.params;
    const photo = await Photo.findById(id);

    if (!photo) {
      return res.status(404).json({ error: "Photo not found" });
    }

    await cloudinary.uploader.destroy(photo.cloudinaryId);

    await Photo.findByIdAndDelete(id);

    res.json({ message: "Photo deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
