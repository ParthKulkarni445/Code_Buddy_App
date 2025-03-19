const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRouter = require('./auth');
require('dotenv').config();

const PORT = process.env.PORT || 3000;
const app = express();
const DB= process.env.DB;
app.use(authRouter);
app.use(cors());

console.log(DB);
mongoose.connect(DB).then(() => {
  console.log("Connection successful");
}).catch((err) => console.log(err));

app.listen(PORT, "0.0.0.0",() => {
  console.log(`Server is running on port ${PORT}`);
});