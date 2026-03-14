const Warehouse = require("../models/warehouse");

async function getWarehouses(req, res) {
  try {
    const warehouses = await Warehouse.findAll({
      where: { isActive: true },
      order: [["name", "ASC"]],
    });
    return res.json(warehouses);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

async function createWarehouse(req, res) {
  try {
    const { code, name, location } = req.body ?? {};

    if (!code || !name) {
      return res
        .status(400)
        .json({ message: "Code and name are required." });
    }

    const warehouse = await Warehouse.create({
      code: String(code).trim(),
      name: String(name).trim(),
      location: String(location ?? "").trim(),
    });

    return res.status(201).json(warehouse);
  } catch (error) {
    if (error.name === "SequelizeUniqueConstraintError") {
      return res
        .status(409)
        .json({ message: "Warehouse code already exists." });
    }
    return res.status(500).json({ message: error.message });
  }
}

async function updateWarehouse(req, res) {
  try {
    const { id } = req.params;
    const { name, location, isActive } = req.body ?? {};

    const warehouse = await Warehouse.findByPk(id);
    if (!warehouse) {
      return res.status(404).json({ message: "Warehouse not found." });
    }

    if (name) warehouse.name = String(name).trim();
    if (location !== undefined) warehouse.location = String(location).trim();
    if (isActive !== undefined) warehouse.isActive = isActive;

    await warehouse.save();
    return res.json(warehouse);
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
}

module.exports = { getWarehouses, createWarehouse, updateWarehouse };
