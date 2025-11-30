# arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python312:20
import logging
import pandas as pd

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def dummy():
    """
    Dummy implementation that takes no input and returns a static result.
    """
    return {
        "status": "ok",
        "message": "dummy implementation - no input required",
        "data": {"example": 42},
    }


def handler(event=None, context=None):
    """
    Lambda entrypoint that ignores any input and returns a deterministic dummy response.
    Keeps the usual (event, context) signature for AWS Lambda compatibility.
    """
    logger.info("Returning dummy response (event ignored).")
    try:
        return dummy()
    except Exception as e:
        logger.exception("Dummy handler failed")
        return {"status": "error", "message": str(e)}
