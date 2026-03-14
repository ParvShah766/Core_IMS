const { Sequelize } = require("sequelize");

const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: "postgres",
  logging: false,
});

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log("PostgreSQL Connected");
    
    // Import and define models after connection
    const User = require("../models/user");
    const Product = require("../models/product");
    const StockLedger = require("../models/stockledger");
    const Warehouse = require("../models/warehouse");
    const InventoryDocument = require("../models/inventoryDocument");
    
    // Sync all models with database
    await sequelize.sync({ alter: true });
    console.log("Database synchronized");
  } catch (error) {
    console.error("Database connection error:", error.message);
    process.exit(1);
  }
};

module.exports = { sequelize, connectDB };