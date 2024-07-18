# Combined Dockerfile for Langchain, OpenAI, and Anthropic (Python)
FROM python:3.9-slim as base

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

FROM base as dev-sdk

# Add an argument for the SDK to be installed
ARG CLOUD_SDK

# Use a conditional to install the specified CLOUD_SDK
RUN if [ "$CLOUD_SDK" = "aws" ]; then pip install --no-cache-dir boto3; \
    elif [ "$CLOUD_SDK" = "gcp" ]; then pip install --no-cache-dir google-cloud; \
    elif [ "$CLOUD_SDK" = "azure" ]; then pip install --no-cache-dir azure; \
    elif [ "$CLOUD_SDK" = "vertex" ]; then pip install --no-cache-dir google-cloud-aiplatform; \
    else echo "No valid CLOUD_SDK specified, skipping CLOUD_SDK installation"; fi

# AI Stage
FROM dev-sdk as dev

# Copy the application code
COPY ./src/ .

# Set environment variables based on the selected SDK
ARG API_KEY
ARG LLM_PROVIDER
ENV OPENAI_API_KEY=$API_KEY

# Install AI
RUN if [ "$LLM_PROVIDER" = "openai" ]; then pip install --no-cache-dir openai; \
    elif [ "$LLM_PROVIDER" = "anthropic" ]; then pip install --no-cache-dir llama-index-llms-anthropic; \ 
    else echo "No Valid LLM chosen."; fi


# Install Python dependencies
COPY src/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on
EXPOSE 8501

# Command to run the application
ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
