const Product = require("../models/product");
const StockLedger = require("../models/stockledger");
const InventoryDocument = require("../models/inventoryDocument");
const Warehouse = require("../models/warehouse");

async function getStockLedger(req, res) {
  try {
    const { productId, movementType, low } = req.query;

    let where = {};
    if (productId) where.productId = productId;
    if (movementType) where.movementType = movementType;

    const ledger = await StockLedger.findAll({
      where,
      include: [{ model: Product, as: "product" }],
      order: [["createdAt", "DESC"]],
    });

    if (low === "true") {
      // Return low stock alerts
      const products = await Product.findAll();
      const alerts = [];

      for (const product of products) {
        const stockByLocation = product.stockByLocation || {};
        for (const [location, quantity] of Object.entries(stockByLocation)) {
          if (quantity <= product.reorderPoint) {
            alerts.push({
              skuCode: product.skuCode,
              productName: product.name,
              location,
              quantity,
              reorderPoint: product.reorderPoint,
              category: product.category,
            });
          }
        }
      }
      return res.json(alerts);
    }

    return res.json(ledger);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function createReceipt(req, res) {
  try {
    const { warehouseId, supplier, location, notes, items } = req.body ?? {};

    if (!warehouseId || !supplier || !items || items.length === 0) {
      return res.status(400).json({
        message:
          "WarehouseId, supplier, and items are required.",
      });
    }

    const warehouse = await Warehouse.findByPk(warehouseId);
    if (!warehouse) {
      return res.status(404).json({ message: "Warehouse not found." });
    }

    // Generate receipt reference
    const count = await InventoryDocument.count({
      where: { type: "receipts" },
    });
    const reference = `RCV-${Date.now().toString().slice(-6)}${String(count + 1).padStart(
      3,
      "0"
    )}`;

    // Create inventory document
    const doc = await InventoryDocument.create({
      reference,
      type: "receipts",
      status: "ready",
      warehouseId,
      location: String(location ?? "").trim(),
      supplier: String(supplier).trim(),
      notes: String(notes ?? "").trim(),
      items,
    });

    // Update product stock and create ledger entries
    for (const item of items) {
      const product = await Product.findOne({
        where: { skuCode: item.skuCode },
      });

      if (!product) {
        return res.status(404).json({
          message: `Product ${item.skuCode} not found.`,
        });
      }

      // Update stock by location
      const stockByLocation = product.stockByLocation || {};
      stockByLocation[location || "General"] =
        (stockByLocation[location || "General"] || 0) + item.quantity;
      
      // Update product with changed flag for JSONB
      await Product.update(
        { stockByLocation },
        { where: { id: product.id } }
      );

      // Create ledger entry
      await StockLedger.create({
        productId: product.id,
        movementType: "RECEIPT",
        quantity: item.quantity,
        toLocation: location || "General",
        reference,
        supplier: String(supplier).trim(),
        note: `Receipt from ${supplier}`,
      });
    }

    return res.status(201).json(doc);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function createDelivery(req, res) {
  try {
    const { warehouseId, customer, location, notes, items } = req.body ?? {};

    if (!warehouseId || !customer || !items || items.length === 0) {
      return res.status(400).json({
        message:
          "WarehouseId, customer, and items are required.",
      });
    }

    const warehouse = await Warehouse.findByPk(warehouseId);
    if (!warehouse) {
      return res.status(404).json({ message: "Warehouse not found." });
    }

    // Generate delivery reference
    const count = await InventoryDocument.count({
      where: { type: "deliveries" },
    });
    const reference = `DLV-${Date.now().toString().slice(-6)}${String(count + 1).padStart(
      3,
      "0"
    )}`;

    // Create inventory document
    const doc = await InventoryDocument.create({
      reference,
      type: "deliveries",
      status: "ready",
      warehouseId,
      location: String(location ?? "").trim(),
      customer: String(customer).trim(),
      notes: String(notes ?? "").trim(),
      items,
    });

    // Update product stock and create ledger entries
    for (const item of items) {
      const product = await Product.findOne({
        where: { skuCode: item.skuCode },
      });

      if (!product) {
        return res.status(404).json({
          message: `Product ${item.skuCode} not found.`,
        });
      }

      // Update stock by location
      const stockByLocation = product.stockByLocation || {};
      const currentStock = stockByLocation[location || "General"] || 0;

      if (currentStock < item.quantity) {
        return res.status(400).json({
          message: `Insufficient stock for ${item.skuCode} at location ${location}.`,
        });
      }

      stockByLocation[location || "General"] -= item.quantity;
      
      // Update product with changed flag for JSONB
      await Product.update(
        { stockByLocation },
        { where: { id: product.id } }
      );

      // Create ledger entry
      await StockLedger.create({
        productId: product.id,
        movementType: "DELIVERY",
        quantity: item.quantity,
        fromLocation: location || "General",
        reference,
        customer: String(customer).trim(),
        note: `Delivery to ${customer}`,
      });
    }

    return res.status(201).json(doc);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function createTransfer(req, res) {
  try {
    const { warehouseId, fromLocation, toLocation, notes, items } = req.body ?? {};

    if (!warehouseId || !fromLocation || !toLocation || !items || items.length === 0) {
      return res.status(400).json({
        message:
          "warehouseId, fromLocation, toLocation, and items are required.",
      });
    }

    // Generate transfer reference
    const count = await InventoryDocument.count({
      where: { type: "internal" },
    });
    const reference = `INT-${Date.now().toString().slice(-6)}${String(count + 1).padStart(
      3,
      "0"
    )}`;

    // Create inventory document
    const doc = await InventoryDocument.create({
      reference,
      type: "internal",
      status: "ready",
      warehouseId,
      location: String(fromLocation).trim(),
      notes: String(notes ?? "").trim(),
      items,
    });

    // Update product stock and create ledger entries
    for (const item of items) {
      const product = await Product.findOne({
        where: { skuCode: item.skuCode },
      });

      if (!product) {
        return res.status(404).json({
          message: `Product ${item.skuCode} not found.`,
        });
      }

      // Update stock by location
      const stockByLocation = product.stockByLocation || {};
      const currentStock = stockByLocation[fromLocation] || 0;

      if (currentStock < item.quantity) {
        return res.status(400).json({
          message: `Insufficient stock for ${item.skuCode} at ${fromLocation}.`,
        });
      }

      stockByLocation[fromLocation] -= item.quantity;
      stockByLocation[toLocation] = (stockByLocation[toLocation] || 0) + item.quantity;
      
      // Update product with changed flag for JSONB
      await Product.update(
        { stockByLocation },
        { where: { id: product.id } }
      );

      // Create ledger entry
      await StockLedger.create({
        productId: product.id,
        movementType: "TRANSFER",
        quantity: item.quantity,
        fromLocation,
        toLocation,
        reference,
        note: `Transfer from ${fromLocation} to ${toLocation}`,
      });
    }

    return res.status(201).json(doc);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function createAdjustment(req, res) {
  try {
    const { warehouseId, location, notes, items } = req.body ?? {};

    if (!warehouseId || !location || !items || items.length === 0) {
      return res.status(400).json({
        message: "warehouseId, Location and items are required.",
      });
    }

    // Generate adjustment reference
    const count = await InventoryDocument.count({
      where: { type: "adjustments" },
    });
    const reference = `ADJ-${Date.now().toString().slice(-6)}${String(count + 1).padStart(
      3,
      "0"
    )}`;

    // Create inventory document
    const doc = await InventoryDocument.create({
      reference,
      type: "adjustments",
      status: "ready",
      warehouseId,
      location: String(location).trim(),
      notes: String(notes ?? "").trim(),
      items,
    });

    // Update product stock and create ledger entries
    for (const item of items) {
      const product = await Product.findOne({
        where: { skuCode: item.skuCode },
      });

      if (!product) {
        return res.status(404).json({
          message: `Product ${item.skuCode} not found.`,
        });
      }

      // Update stock by location
      const stockByLocation = product.stockByLocation || {};
      stockByLocation[location] = (stockByLocation[location] || 0) + item.quantity;
      
      // Update product with changed flag for JSONB
      await Product.update(
        { stockByLocation },
        { where: { id: product.id } }
      );

      // Create ledger entry
      await StockLedger.create({
        productId: product.id,
        movementType: "ADJUSTMENT",
        quantity: item.quantity,
        toLocation: location,
        reference,
        note: `Stock adjustment: ${notes || "No reason provided"}`,
      });
    }

    return res.status(201).json(doc);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function getInventoryDocuments(req, res) {
  try {
    const { type, status, warehouseId } = req.query;

    let where = {};
    if (type) where.type = type;
    if (status) where.status = status;
    if (warehouseId) where.warehouseId = warehouseId;

    const docs = await InventoryDocument.findAll({
      where,
      include: [{ model: Warehouse, as: "warehouse" }],
      order: [["createdAt", "DESC"]],
    });

    return res.json(docs);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

module.exports = {
  getStockLedger,
  createReceipt,
  createDelivery,
  createTransfer,
  createAdjustment,
  getInventoryDocuments,
};
