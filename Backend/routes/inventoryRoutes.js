const express = require("express");

const { receiveStock, deliverStock } = require("../controllers/inventoryController");

const router = express.Router();

router.post("/receive", receiveStock);
router.post("/deliver", deliverStock);

module.exports = router;
