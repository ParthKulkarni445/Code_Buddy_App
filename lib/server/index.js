const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRouter = require('./auth');
require('dotenv').config();

const PORT = process.env.PORT || 3000;
const app = express();
const DB= "mongodb+srv://2023csb1142:ManishaParth5671@cluster0.9elc5.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
app.use(authRouter);
app.use(cors());

mongoose.connect(DB).then(() => {
  console.log("Connection successful");
}).catch((err) => console.log(err));

app.listen(PORT, "0.0.0.0",() => {
  console.log(`Server is running on port ${PORT}`);
});