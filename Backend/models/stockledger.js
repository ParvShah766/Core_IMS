const { DataTypes } = require("sequelize");
const { sequelize } = require("../config/db");
const Product = require("./product");

const StockLedger = sequelize.define(
  "StockLedger",
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    productId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: Product,
        key: "id",
      },
    },
    movementType: {
      type: DataTypes.ENUM("RECEIPT", "DELIVERY", "TRANSFER", "ADJUSTMENT"),
      allowNull: false,
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    fromLocation: {
      type: DataTypes.STRING,
      defaultValue: null,
    },
    toLocation: {
      type: DataTypes.STRING,
      defaultValue: null,
    },
    reference: {
      type: DataTypes.STRING,
      defaultValue: "",
    },
    supplier: {
      type: DataTypes.STRING,
      defaultValue: "",
    },
    customer: {
      type: DataTypes.STRING,
      defaultValue: "",
    },
    note: {
      type: DataTypes.STRING,
      defaultValue: "",
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

StockLedger.belongsTo(Product, { foreignKey: "productId", as: "product" });
Product.hasMany(StockLedger, { foreignKey: "productId", as: "ledgers" });

module.exports = StockLedger;
