from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import pipeline

app = FastAPI(title="Sentiment Analysis API")

# 1. Define a Pydantic model to validate input
class TextIn(BaseModel):
    text: str

# 2. Load the HuggingFace pipeline once at startup
#    Use the small distilbert model for sentiment analysis
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

@app.post("/predict")
async def predict(payload: TextIn):
    """
    Accepts JSON: { "text": "your input string" }
    Returns: { "label": "POSITIVE", "score": 0.xx }
    """
    if not payload.text:
        raise HTTPException(status_code=400, detail="Text field is required.")
    result = classifier(payload.text[:512])  # Truncate long text to 512 tokens
    # classifier returns a list: e.g. [ {"label": "POSITIVE", "score": 0.999} ]
    return {"label": result[0]["label"], "score": float(result[0]["score"])}
