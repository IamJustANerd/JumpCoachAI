from flask import Flask, request, jsonify
import google.generativeai as genai
import numpy as np
import onnxruntime as ort

# ================================
# CONFIG - GEMINI API
# ================================
GOOGLE_API_KEY = "AIzaSyChFThwJI3079pGTxamCMVFCuCyHd9qWLU" 
genai.configure(api_key=GOOGLE_API_KEY)

# ================================
# LOAD ONNX MODEL
# ================================
onnx_session = ort.InferenceSession("model2.onnx")

# ================================
# AI COACH FUNCTION (LLM)
# ================================
def generate_jump_feedback(jump_data):
    system_instruction = """
    Role: Anda adalah pelatih performa atletik profesional.
    Task: Analisis data lompatan user dan berikan feedback konstruktif.

    Constraints:
    - Bahasa Indonesia
    - Maksimal 3 kalimat
    - Jika score > 80 → beri pujian
    - Jika score < 50 → beri koreksi dasar
    """

    user_prompt = f"""
    Tolong review performa lompatan saya:
    - Total Score: {jump_data['score']}
    - Tilt: {jump_data['tilt_deg_mean']} derajat
    - Airtime: {jump_data['airtime_s']} detik
    - Jump vs Height Ratio: {jump_data['jump_vs_height']}
    """

    try:
        model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',
            system_instruction=system_instruction
        )

        response = model.generate_content(
            contents=user_prompt,
            generation_config=genai.types.GenerationConfig(temperature=0.7)
        )

        return response.text.strip()

    except Exception as e:
        return f"Error: {str(e)}"


# ================================
# ONNX INFERENCE FUNCTION
# ================================
def predict_score(data):
    """
    Input JSON fields:
    - height_m
    - weight_kg
    - airtime_s
    - max_jump_m
    - jump_vs_height
    - tilt_deg_mean
    """

    # Convert dict → numpy array (1 row, 6 features)
    X = np.array([[
        float(data["height_m"]),
        float(data["weight_kg"]),
        float(data["airtime_s"]),
        float(data["max_jump_m"]),
        float(data["jump_vs_height"]),
        float(data["tilt_deg_mean"])
    ]], dtype=np.float32)

    # ONNX input name
    input_name = onnx_session.get_inputs()[0].name

    # Run inference
    prediction = onnx_session.run(None, {input_name: X})

    # Assume output is a single float
    score = float(prediction[0][0])

    return score


# ================================
# FLASK SERVER
# ================================
app = Flask(__name__)


@app.route("/")
def home():
    return "Local Jump AI Server is running!"


# ----------- LLM FEEDBACK ENDPOINT -------------
@app.route("/generate_feedback", methods=["POST"])
def api_generate_feedback():
    try:
        data = request.json
        result = generate_jump_feedback(data)
        return jsonify({"feedback": result})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ----------- ONNX SCORE PREDICTION ENDPOINT -------------
@app.route("/predict_score", methods=["POST"])
def api_predict_score():
    try:
        data = request.json
        score = predict_score(data)
        return jsonify({"score": score})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================================
# RUN SERVER
# ================================
if __name__ == "__main__":
    print("🔥 Local AI Server running at http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000, debug=True)
