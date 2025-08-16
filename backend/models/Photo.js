const mongoose = require("mongoose");

const photoSchema = new mongoose.Schema(
  {
    imageUrl: {
      type: String,
      required: true,
    },
    cloudinaryId: {
      type: String,
      required: true,
    },
    coordX: {
      type: Number,
      required: true,
    },
    coordY: {
      type: Number,
      required: true,
    },
    location: {
      type: String,
      default: "",
    },
    difficulty: {
      type: String,
      enum: ["easy", "medium", "hard"],
      default: "medium",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Photo", photoSchema);
