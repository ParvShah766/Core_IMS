const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const User = sequelize.define(
  "User",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      lowercase: true,
      trim: true,
      validate: {
        isEmail: true,
      },
    },
    passwordHash: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    fullName: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
    role: {
      type: DataTypes.ENUM("inventoryManager", "warehouseStaff"),
      defaultValue: "inventoryManager",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = User;
