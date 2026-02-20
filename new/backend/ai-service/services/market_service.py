import requests
import os

API_KEY = os.getenv("MANDI_API_KEY")

def get_mandi_price(crop_name):

    url = f"https://api.data.gov.in/resource/mandi-prices"

    params = {
        "api-key": API_KEY,
        "format": "json",
        "filters[commodity]": crop_name,
        "limit": 10
    }

    response = requests.get(url, params=params)
    data = response.json()

    return data
