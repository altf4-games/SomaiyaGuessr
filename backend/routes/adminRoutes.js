const express = require("express");
const router = express.Router();
const multer = require("multer");
const adminController = require("../controllers/adminController");

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed!"), false);
    }
  },
});

// Admin routes
router.post(
  "/upload-photo",
  upload.single("photo"),
  adminController.uploadPhoto
);
router.get("/photos", adminController.getAllPhotos);
router.delete("/photos/:id", adminController.deletePhoto);

module.exports = router;
