import json

def lambda_handler(event, context):
    """
    Lambda entry point.
    
    Parameters:
    ----------
    event : dict
        The input event to the Lambda function (API Gateway, S3, custom event, etc.)
    context : LambdaContext
        Runtime information provided by AWS Lambda.
    
    Returns:
    -------
    dict
        JSON response (if using API Gateway)
    """
    
    # Log event for debugging
    print("Received event:", json.dumps(event))
    
    # Example: Extract a query parameter or body value
    name = None
    if "queryStringParameters" in event and event["queryStringParameters"]:
        name = event["queryStringParameters"].get("name", "World")
    else:
        name = "World"

    # Create response
    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": f"Hello, {name}!",
            "input_event": event
        })
    }
    
    return response


if __name__ == "__main__":
    # Mock event for local testing
    test_event = {
        "name": "Local Test"
    }
    
    # Mock context for local testing
    class Context:
        function_name = "local-test-lambda"
        memory_limit_in_mb = 128
        aws_request_id = "123456789"
        def get_remaining_time_in_millis(self): return 30000
    
    context = Context()
    
    response = lambda_handler(test_event, context)
    print("Lambda Response:", response)