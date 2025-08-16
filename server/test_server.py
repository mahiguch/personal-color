"""
Simple test server without Google Cloud dependencies
"""

from fastapi import FastAPI
import uvicorn

app = FastAPI(title="Personal Color API Test", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Personal Color API Test Server", "status": "running"}

@app.get("/health")
async def health():
    return {"status": "healthy", "message": "Basic server is working"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)