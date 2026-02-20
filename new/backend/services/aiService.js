const axios = require("axios");
const FormData = require("form-data");
const fs = require("fs");

exports.callAIService = async (imagePath) => {
  const form = new FormData();
  form.append("file", fs.createReadStream(imagePath));

  const response = await axios.post(
    process.env.AI_SERVICE_URL,
    form,
    {
      headers: form.getHeaders(),
    }
  );

  const data = response.data;

  // Ensure confidence matches DECIMAL(5,4)
  data.confidence = parseFloat(Number(data.confidence).toFixed(4));

  return data;
};
