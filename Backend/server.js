require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");

const { connectDB } = require("./config/db");
const User = require("./models/user");
const Product = require("./models/product");

const {
  getWarehouses,
  createWarehouse,
  updateWarehouse,
} = require("./controllers/warehouseController");
const {
  getStockLedger,
  createReceipt,
  createDelivery,
  createTransfer,
  createAdjustment,
  getInventoryDocuments,
} = require("./controllers/stockController");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Inventory API Running");
});

app.get("/api/health", (req, res) => {
  res.json({ ok: true, service: "ims-backend" });
});

app.post("/api/auth/signup", async (req, res) => {
  try {
    const email = String(req.body?.email ?? "").trim().toLowerCase();
    const password = String(req.body?.password ?? "");

    if (!email || !email.includes("@")) {
      return res.status(400).json({ message: "Enter a valid email." });
    }
    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password should be at least 6 characters." });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({ message: "Email is already registered." });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      email,
      passwordHash,
      fullName: email.split("@")[0],
      role: "inventoryManager",
    });

    return res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.post("/api/auth/login", async (req, res) => {
  try {
    const email = String(req.body?.email ?? "").trim().toLowerCase();
    const password = String(req.body?.password ?? "");

    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: "Invalid email or password." });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ message: "Invalid email or password." });
    }

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.get("/api/products", async (req, res) => {
  try {
    const products = await Product.findAll({ order: [["createdAt", "DESC"]] });
    return res.json(products);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.post("/api/products", async (req, res) => {
  try {
    const payload = req.body ?? {};
    const skuCode = String(payload.skuCode ?? "").trim();
    const name = String(payload.name ?? "").trim();
    const category = String(payload.category ?? "").trim();
    const unitOfMeasure = String(payload.unitOfMeasure ?? "").trim();
    const reorderPoint = Number(payload.reorderPoint ?? 0);
    const reorderQuantity = Number(payload.reorderQuantity ?? 0);
    const stockByLocation =
      payload.stockByLocation && typeof payload.stockByLocation === "object"
        ? payload.stockByLocation
        : {};

    if (!skuCode || !name || !category || !unitOfMeasure) {
      return res.status(400).json({
        message: "skuCode, name, category and unitOfMeasure are required.",
      });
    }

    const [product, created] = await Product.findOrCreate({
      where: { skuCode },
      defaults: {
        name,
        category,
        unitOfMeasure,
        reorderPoint: Number.isNaN(reorderPoint) ? 0 : reorderPoint,
        reorderQuantity: Number.isNaN(reorderQuantity) ? 0 : reorderQuantity,
        stockByLocation,
      },
    });

    if (!created) {
      await product.update({
        name,
        category,
        unitOfMeasure,
        reorderPoint: Number.isNaN(reorderPoint) ? 0 : reorderPoint,
        reorderQuantity: Number.isNaN(reorderQuantity) ? 0 : reorderQuantity,
        stockByLocation,
      });
    }

    return res.status(201).json(product);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.put("/api/products/:skuCode", async (req, res) => {
  try {
    const skuCode = String(req.params.skuCode ?? "").trim();
    if (!skuCode) {
      return res.status(400).json({ message: "Invalid skuCode." });
    }

    const payload = req.body ?? {};
    const product = await Product.findOne({ where: { skuCode } });

    if (!product) {
      return res.status(404).json({ message: "Product not found." });
    }

    await product.update(payload);

    return res.json(product);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

// Warehouse endpoints
app.get("/api/warehouses", getWarehouses);
app.post("/api/warehouses", createWarehouse);
app.put("/api/warehouses/:id", updateWarehouse);

// Stock ledger and movement endpoints
app.get("/api/stock-ledger", getStockLedger);
app.post("/api/stock-movements/receipt", createReceipt);
app.post("/api/stock-movements/delivery", createDelivery);
app.post("/api/stock-movements/transfer", createTransfer);
app.post("/api/stock-movements/adjustment", createAdjustment);

// Inventory documents endpoints
app.get("/api/inventory-documents", getInventoryDocuments);

// Import and setup routes
const authRoutes = require("./routes/authRoutes");
app.use("/api/auth", authRoutes);

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer().catch((error) => {
  console.error("Failed to start server:", error);
  process.exit(1);
});