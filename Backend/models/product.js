const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");

const Product = sequelize.define(
  "Product",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    skuCode: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      trim: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      trim: true,
    },
    category: {
      type: DataTypes.STRING,
      allowNull: false,
      trim: true,
    },
    unitOfMeasure: {
      type: DataTypes.STRING,
      allowNull: false,
      trim: true,
    },
    reorderPoint: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      validate: {
        min: 0,
      },
    },
    reorderQuantity: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      validate: {
        min: 0,
      },
    },
    stockByLocation: {
      type: DataTypes.JSONB,
      defaultValue: {},
    },
  },
  {
    timestamps: true,
  }
);

module.exports = Product;