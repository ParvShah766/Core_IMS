const Product = require("../models/product");

exports.createProduct = async (req, res) => {

  try {

    const product = new Product(req.body);

    await product.save();

    res.json(product);

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};

exports.getProducts = async (req, res) => {

  try {

    const products = await Product.find();

    res.json(products);

  } catch (error) {

    res.status(500).json({ error: error.message });

  }

};