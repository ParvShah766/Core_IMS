const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const Warehouse = require("./warehouse");

const InventoryDocument = sequelize.define(
  "InventoryDocument",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    reference: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      trim: true,
    },
    type: {
      type: DataTypes.ENUM("receipts", "deliveries", "internal", "adjustments"),
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM("waiting", "ready", "draft", "completed", "cancelled"),
      defaultValue: "draft",
    },
    warehouseId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: Warehouse,
        key: "id",
      },
    },
    location: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
    category: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
    supplier: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
    customer: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
    notes: {
      type: DataTypes.TEXT,
      defaultValue: "",
    },
    items: {
      type: DataTypes.JSONB,
      defaultValue: [],
    },
  },
  {
    timestamps: true,
  }
);

InventoryDocument.belongsTo(Warehouse, { foreignKey: "warehouseId", as: "warehouse" });
Warehouse.hasMany(InventoryDocument, { foreignKey: "warehouseId", as: "documents" });

module.exports = InventoryDocument;
