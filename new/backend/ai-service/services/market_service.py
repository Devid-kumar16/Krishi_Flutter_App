import requests

API_KEY = "579b464db66ec23bdd000001ac3ddec914f74b546477ab9b011094c7"

BASE_URL = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"


def get_mandi_price(crop_name="Tomato"):
    try:
        # ✅ Clean crop input
        crop_name = crop_name.strip().title()

        params = {
            "api-key": API_KEY,
            "format": "json",
            "limit": 20,
            "filters[commodity]": crop_name
        }

        response = requests.get(BASE_URL, params=params, timeout=10)

        # ✅ Check API response
        if response.status_code != 200:
            return {
                "success": False,
                "data": [],
                "error": f"API failed with status {response.status_code}"
            }

        data = response.json()

        # ✅ Extract records safely
        records = []
        if isinstance(data, dict):
            records = data.get("records", [])
        elif isinstance(data, list):
            records = data

        # ✅ If no data found
        if not records:
            return {
                "success": True,
                "data": [],
                "message": "No data found"
            }

        # ✅ Format response (IMPORTANT for Flutter)
        results = []

        for item in records:
            results.append({
                "crop": item.get("commodity", ""),
                "market": item.get("market", ""),
                "state": item.get("state", ""),
                "price": item.get("modal_price", "0")
            })

        return {
            "success": True,
            "data": results
        }

    except requests.exceptions.RequestException as e:
        return {
            "success": False,
            "data": [],
            "error": f"Network error: {str(e)}"
        }

    except Exception as e:
        return {
            "success": False,
            "data": [],
            "error": f"Server error: {str(e)}"
        }