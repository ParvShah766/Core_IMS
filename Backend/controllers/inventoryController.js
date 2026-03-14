const Product = require("../models/product");
const Ledger = require("../models/stockledger");

exports.receiveStock = async (req, res) => {

  try {

    const { productId, quantity } = req.body;

    if (!productId || !quantity || quantity <= 0) {

      return res.status(400).json({ error: "Invalid productId or quantity" });

    }

    const product = await Product.findById(productId);

    if (!product) {

      return res.status(404).json({ error: "Product not found" });

    }

    product.stock += quantity;

    await product.save();

    await Ledger.create({

      productId,

      movementType: "RECEIPT",

      quantity

    });

    res.json({ message: "Stock received" });

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};

exports.deliverStock = async (req, res) => {

  try {

    const { productId, quantity } = req.body;

    if (!productId || !quantity || quantity <= 0) {

      return res.status(400).json({ error: "Invalid productId or quantity" });

    }

    const product = await Product.findById(productId);

    if (!product) {

      return res.status(404).json({ error: "Product not found" });

    }

    if (product.stock < quantity) {

      return res.status(400).json({ error: "Insufficient stock" });

    }

    product.stock -= quantity;

    await product.save();

    await Ledger.create({

      productId,

      movementType: "DELIVERY",

      quantity: -quantity

    });

    res.json({ message: "Stock delivered" });

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};